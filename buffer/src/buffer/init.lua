-- Copyright 2018 the wonderful GUI project authors
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

--- Display buffers and buffer view.
-- @see 205-Buffer.md
-- @module wonderful.buffer

-- The code isn't quite readable here. Well, once upon the time it was, only to
-- have disappointing perfomance. You can observe the same thing in
-- `wonderful.buffer.storage5x` modules as well as in `wonderful.util.palette`.
--
-- Remember, we're trying to build a **fast** library to replace direct GPU
-- calls. What's out goal? A fill on a T3 setup, which has the call budget of
-- 1.5, takes 1/128 of the budget. If my math is correct, this means we can
-- issue up to 192 fiils a tick. So the fill methods should take up to
-- 260.4166667 microseconds (a millionth of a second) to run.
--
-- Similarly, a set call should run in 130.2083333 µs or less — twice as fast.
--
-- Is that possible? Am I serious? The answer is "not really" — to the both
-- questions. But we can try.
--
-- What should we look at when we're trying to optimize the code running in OC?
-- There's common sense that tells us not to do anything stupid. But it's
-- not enough. We need to optimize it even further.
--
-- Calls are expensive. Usually they aren't unless you make a few thousand
-- calls. But a whole-screen fill should run some code for 160 × 50 = 8000
-- cells, so we should avoid redundant calls there. We can *inline* functions:
-- bascially, copy-paste and fix variable names. A caveat is that maintaining
-- such code is very hard: if we fix a bug in a function, we also have to fix
-- it wherever it's inlined.
--
-- It's also important to note that in OC before 1.7.3, the checkDeadline hook
-- is run every 100 Lua VM instructions. Hooks are highly expensive. We don't
-- want them to be run.
--
-- And there are other expensive things we try to avoid. The resulting code is
-- messy, unreadable, hardly maintainable. We know that. And we're sorry.

local unicode = require("unicode")

local class = require("lua-objects")

local geometry = require("wonderful.geometry")
local palette = require("wonderful.util.palette")

local storageMod

if _VERSION == "Lua 5.3" then
  storageMod = require("wonderful.buffer.storage53")
else
  storageMod = require("wonderful.buffer.storage52")
end

--- A non-renderable buffer.
local Buffer = class(nil, {name = "wonderful.buffer.Buffer"})

local BufferView

--- A non-renderable buffer.
-- @type Buffer

--- A buffer width.
-- @field Buffer.w

--- A buffer height.
-- @field Buffer.h

--- A palette the buffer uses.
-- @field Buffer.palette

--- A buffer depth.
-- @field Buffer.depth

--- Construct a new buffer.
--
-- The debug mode introduces a few sanity checks. They allow to notice the
-- potential bugs and errors, but also slow down the program significantly.
--
-- @tparam table args a keyword argument table
-- @tparam int args.w a width of buffer
-- @tparam int args.h a height of buffer
-- @tparam int args.depth a color depth
-- @tparam boolean args.debug whether the debug mode should be set
function Buffer:__new__(args)
  self.w = args.w
  self.h = args.h
  self.depth = args.depth

  if args.debug == nil then
    self.debug = true
  else
    self.debug = not not args.debug
  end

  self.box = geometry.Box(1, 1, self.w, self.h)

  if self.depth == 1 then
    self.palette = palette.t1
  elseif self.depth == 4 then
    self.palette = palette.t2
  elseif self.depth == 8 then
    self.palette = palette.t3
  end

  local cells = self.w * self.h

  if cells <= 25 * 16 then
    self.storage = storageMod.BufferStorageT1(self.w, self.h)
  elseif cells <= 50 * 25 then
    self.storage = storageMod.BufferStorageT2(self.w, self.h)
  elseif cells <= 160 * 50 then
    self.storage = storageMod.BufferStorageT3(self.w, self.h)
  else
    error(("Unsupported resolution: %d×%d"):format(self.w, self.h))
  end

  self.storage:optimize()

  self.defaultColor = 0xffffff000000
end

--- Check if a cell belongs to the buffer.
-- @tparam int x a row number
-- @tparam int y a row number
-- @treturn boolean
function Buffer:inRange(x, y)
  if self.debug then
    checkArg(1, x, "number")
    checkArg(2, y, "number")
  end

  return self.box:has(x, y)
end

--- Perform alpha blending of two colors.
-- @tparam int color1 the first color
-- @tparam int color2 the second color
-- @tparam number alpha an opacity (an alpha value ∈ [0; 1])
-- @treturn int the result of alpha blending
function Buffer:alphaBlend(color1, color2, alpha)
  if self.debug then
    checkArg(1, color1, "number")
    checkArg(2, color2, "number")
    checkArg(3, alpha, "number")

    if alpha < 0 or alpha > 1 then
      error("bad argument #3: alpha ∉ [0; 1]", 1)
    end
  end

  if color1 == color2 then
    return color1
  end

  if alpha == 0 then
    return color1
  end

  if alpha == 1 then
    return color2
  end

  local r1, g1, b1 = palette.extract(color1)
  local r2, g2, b2 = palette.extract(color2)

  local ialpha = 1 - alpha

  local r = r1 * ialpha + r2 * alpha + 0.5
  local g = g1 * ialpha + g2 * alpha + 0.5
  local b = b1 * ialpha + b2 * alpha + 0.5

  return (r - r % 1) * 0x10000 +
         (g - g % 1) * 0x100 +
         (b - b % 1)
end

--- Set a cell.
--
-- This is an internal method that **does not** perform sanity checks.
-- Futhermore, unlike @{wonderful.buffer.Buffer:set}, this method only sets
-- a single cell per call.
--
-- @tparam int x a column number
-- @tparam int y a row number
-- @tparam int ?fg a foreground color
-- @tparam int ?bg a background color
-- @tparam number alpha an opacity (an alpha value ∈ [0; 1])
-- @tparam string ?char a character
-- @see wonderful.buffer.Buffer:set
function Buffer:_set(x, y, fg, bg, alpha, char)
  local storage = self.storage
  local im, jm = storage:indexMain(x, y)
  local id, jd = storage:indexDiff(x, y)

  local mainChar = storage.data[im][jm]
  local mainColor = storage.data[im][jm + 1]
  local diffColor = storage.data[id][jd + 1]

  local old = diffColor or mainColor or self.defaultColor

  -- we don't care about the 49th bit here
  old = old % 0x1000000000000

  local oldBg = old % 0x1000000
  local oldFg = (old - oldBg) / 0x1000000

  if not fg and oldBg ~= oldFg then
    fg = oldFg
  end

  if alpha == 0 then
    fg = oldBg
    bg = oldBg
  elseif alpha == 1 then
    -- Don't change colors.
  else
    if char and oldBg ~= fg and fg then
      fg = self:alphaBlend(oldBg, fg, alpha)
    elseif not char and oldFg ~= fg and fg then
      fg = self:alphaBlend(oldFg, fg, alpha)
    end

    if oldBg ~= bg and bg then
      bg = self:alphaBlend(oldBg, bg, alpha)
    end
  end

  fg = fg or oldFg
  bg = bg or oldBg

  -- set: bytes 4-6 = fg
  --      bytes 1-3 = bg
  local new = fg * 0x1000000 + bg

  if new == (mainColor or self.defaultColor) then
    new = nil
  end

  -- set bit 49 (not reduced to palette)
  storage.data[id][jd + 1] = new and (new + 0x1000000000000)

  if char then
    if char == (mainChar or " ") then
      char = nil
    end

    storage.data[id][jd] = char
  end
end

--- Set a line of characters.
-- @tparam int x0 a column number
-- @tparam int y0 a row number
-- @tparam ?int fg a foreground color
-- @tparam ?int bg a background color
-- @tparam number alpha an opacity (an alpha value ∈ [0; 1])
-- @tparam ?string line a text line
-- @tparam[opt=false] boolean vertical if true, set a vertical line
-- @see wonderful.buffer.Buffer:_set
function Buffer:set(x0, y0, fg, bg, alpha, line, vertical)
  if self.debug then
    checkArg(1, x0, "number")
    checkArg(2, y0, "number")
    checkArg(3, fg, "number", "nil")
    checkArg(4, bg, "number", "nil")
    checkArg(5, alpha, "number")
    checkArg(6, line, "string", "nil")
  end

  if line then
    for i = 1, unicode.len(line), 1 do
      local x, y

      if not vertical then
        x = x0 + i - 1
        y = y0
      else
        x = x0
        y = y0 + i - 1
      end

      if not self:inRange(x, y) then
        return
      end

      self:_set(x, y, fg, bg, alpha, unicode.sub(line, i, i))
    end
  else
    self:_set(x, y, fg, bg, alpha, nil)
  end
end

--- Retrieve a cell from the storage.
--
-- This is an internal method that **does not** perform sanity checks.
-- Futhermore, unlike @{wonderful.buffer.Buffer:get}, this method returns
-- a packed color instead of foreground and background.
--
-- @tparam int x a column number
-- @tparam int y a row number
-- @treturn string a cell's character
-- @treturn int a cell's packed and deflated color
-- @see wonderful.buffer.Buffer:get
function Buffer:_get(x, y)
  local mainChar, mainColor = self.storage:getMain(x, y)
  local id, jd = self.storage:indexDiff(x, y)
  local diffChar = self.storage.data[id][jd]
  local diffColor = self.storage.data[id][jd + 1]

  -- reduce the color if the 49th bit is set
  if diffColor and diffColor >= 0x1000000000000 then
    diffColor = diffColor % 0x1000000000000
    local bg = diffColor % 0x1000000
    local fg = (diffColor - bg) / 0x1000000
    diffColor = (self.palette[self.palette:deflate(fg) + 1] * 0x1000000 +
                 self.palette[self.palette:deflate(bg) + 1])

    if diffColor == (mainColor or self.defaultColor) then
      diffColor = nil
    end

    self.storage.data[id][jd + 1] = diffColor
  end

  return diffChar or mainChar or " ",
         diffColor or mainColor or self.defaultColor
end

--- Retrieve a cell from the storage.
-- @tparam int x a column number
-- @tparam int y a row number
-- @treturn string a cell's character
-- @treturn int a cell's foreground color
-- @treturn int a cell's background color
-- @see wonderful.buffer.Buffer:_get
function Buffer:get(x, y)
  if self.debug then
    checkArg(1, x, "number")
    checkArg(2, y, "number")
  end

  if not self:inRange(x, y) then
    return false
  end

  local char, color = self:_get(x, y)
  local bg = color % 0x1000000
  local fg = (color - bg) / 0x1000000

  return char, fg, bg
end

--- Get an intersection of the buffer and a given sub-box.
-- @tparam int x0 a top-left cell column number
-- @tparam int y0 a top-left cell row number
-- @tparam int w a width of sub-box
-- @tparam int h a height of sub-box
-- @treturn[1] int an intersection's top-left cell column number
-- @treturn[1] int an intersection's top-left cell row number
-- @treturn[1] int an intersection's bottom-right cell column number
-- @treturn[1] int an intersection's bottom-right cell row number
-- @treturn[2] nil the intersection is empty
function Buffer:intersection(x0, y0, w, h)
  if self.debug then
    checkArg(1, x0, "number")
    checkArg(2, y0, "number")
    checkArg(3, w, "number")
    checkArg(4, h, "number")
  end

  if w <= 0 or h <= 0 then
    return
  end

  local x1 = x0 + w - 1
  local y1 = y0 + h - 1

  if x1 < self.box.x or y1 < self.box.y then
    return
  end

  x0 = math.max(x0, self.box.x)
  y0 = math.max(y0, self.box.y)
  x1 = math.min(x1, self.box.x1)
  y1 = math.min(y1, self.box.y1)

  return x0, y0, x1, y1
end

--- Fill an area with a given cell.
--
-- This is an internal method that **does not** perform sanity checks.
-- @tparam int x0 a top-left cell column number
-- @tparam int y0 a top-left cell row number
-- @tparam int x1 a bottom-right cell column number
-- @tparam int y1 a bottom-right cell row number
-- @tparam ?int fg a foreground color
-- @tparam ?int bg a background color
-- @tparam number alpha an opacity (an alpha value ∈ [0; 1])
-- @tparam ?string char a character
-- @see wonderful.buffer.Buffer:fill
function Buffer:_fill(x0, y0, x1, y1, fg, bg, alpha, char)
  local storage = self.storage
  local indexMain = storage.indexMain
  local indexDiff = storage.indexDiff
  local storageData = storage.data
  local defaultColor = self.defaultColor

  local sdMain, sdDiff
  local oim, oid

  for x = x0, x1, 1 do
    for y = y0, y1, 1 do
      local im, jm = indexMain(storage, x, y)
      local id, jd = indexDiff(storage, x, y)

      if oim ~= im then
        sdMain = storageData[im]
        oim = im
      end

      if oid ~= id then
        sdDiff = storageData[id]
        oid = id
      end

      local mainChar = sdMain[jm]
      local mainColor = sdMain[jm + 1]
      local diffColor = sdDiff[jd + 1]

      local old = diffColor or mainColor or defaultColor

      -- we don't care about the 49th bit here
      old = old % 0x1000000000000

      local oldBg = old % 0x1000000
      local oldFg = (old - oldBg) / 0x1000000

      local cfg, cbg = fg, bg

      if not fg and oldBg ~= oldFg then
        cfg = oldFg
      end

      if alpha == 0 then
        cfg = oldBg
        cbg = oldBg
      elseif alpha < 1 then
        -- Don't change colors if alpha == 1
        if char and oldBg ~= cfg and cfg then
          cfg = self:alphaBlend(oldBg, cfg, alpha)
        elseif not char and oldFg ~= cfg and cfg then
          cfg = self:alphaBlend(oldFg, cfg, alpha)
        end

        if oldBg ~= cbg and cbg then
          cbg = self:alphaBlend(oldBg, cbg, alpha)
        end
      end

      cfg = cfg or oldFg
      cbg = cbg or oldBg

      -- set: bytes 4-6 = fg
      --      bytes 1-3 = bg
      local new = cfg * 0x1000000 + cbg

      if new == (mainColor or defaultColor) then
        new = nil
      end

      -- set bit 49 (not reduced to palette)
      sdDiff[jd + 1] = new and (new + 0x1000000000000)

      if char then
        local cchar = char

        if cchar == (mainChar or " ") then
          cchar = nil
        end

        sdDiff[jd] = cchar
      end
    end
  end
end

--- Fill an area with a given cell.
--
-- This method performs sanity checks, which may decrease perfomance
-- significantly if used too often.
-- @tparam int x0 a top-left cell column number
-- @tparam int y0 a top-left cell row number
-- @tparam int w an area width
-- @tparam int h an area width
-- @tparam ?int fg a foreground color
-- @tparam ?int bg a background color
-- @tparam number alpha an opacity (an alpha value ∈ [0; 1])
-- @tparam ?string char a character
-- @see wonderful.buffer.Buffer:_fill
function Buffer:fill(x0, y0, w, h, fg, bg, alpha, char)
  if self.debug then
    checkArg(1, x0, "number")
    checkArg(2, y0, "number")
    checkArg(3, w, "number")
    checkArg(4, h, "number")
    checkArg(5, fg, "number", "nil")
    checkArg(6, bg, "number", "nil")
    checkArg(7, alpha, "number")
    checkArg(8, char, "string", "nil")
  end

  local x0, y0, x1, y1 = self:intersection(x0, y0, w, h)

  if not x0 then
    return
  end

  char = char and unicode.sub(char, 1, 1) or nil

  self:_fill(x0, y0, x1, y1, fg, bg, alpha, char)
end

--- Reset all cells to default.
function Buffer:clear()
  self.storage:clear()
end

--- Create a buffer view.
-- @tparam number x a coordinate box's top-left cell column number
-- @tparam number y a coordinate box's top-left cell row number
-- @tparam number w a coordinate box's width
-- @tparam number h a coordinate box's height
-- @tparam number sx a restricting box's top-left cell column number
-- @tparam number sy a restricting box's top-left cell row number
-- @tparam number sw a restricting box's width
-- @tparam number sh a restricting box's height
-- @treturn wonderful.buffer.BufferView
function Buffer:view(x, y, w, h, sx, sy, sw, sh)
  if self.debug then
    checkArg(1, x, "number")
    checkArg(2, y, "number")
    checkArg(3, w, "number")
    checkArg(4, h, "number")
    checkArg(5, sx, "number")
    checkArg(6, sy, "number")
    checkArg(7, sw, "number")
    checkArg(8, sh, "number")
  end

  -- defines the view (buffer-relative) coordinate system
  local coordBox = geometry.Box(x, y, w, h)

  -- restricts the view
  local restrictBox = geometry.Box(sx, sy, sw, sh)

  -- don't allow to write outside the buffer
  restrictBox = restrictBox:intersection(self.box)

  -- don't allow to write outside the coordinate box
  restrictBox = restrictBox:intersection(coordBox)

  local view = BufferView(self, coordBox, restrictBox, self.debug)
  view:optimize()

  return view
end

--- Copy an area from a buffer and paste it onto self.
--
-- If the source area are omitted, the whole source buffer is copied.
--
-- @param src the source buffer to copy from
-- @tparam[opt] int sx the area's top-left cell column number
-- @tparam[optchain] int sy the area's top-left cell row number
-- @tparam[optchain] int sw the area width
-- @tparam[optchain] int sh the area height
-- @tparam int dx the column at which to paste the area's top-left cell
-- @tparam int dy the row at which to paste the area's top-left cell
function Buffer:copyFrom(src, sx, sy, sw, sh, dx, dy)
  if self.debug then
    if type(src) ~= "table" or not src.isa or not src:isa(Buffer) then
      error(1, "bad argument #1: a buffer is expected")
    end
  end

  if not (sw or sh or dx or dy) then
    -- the area is probably omitted
    dx = sx
    dy = sy
    sx = src.box.x
    sy = src.box.y
    sw = src.box.w
    sh = src.bow.h
  end

  if self.debug then
    checkArg(2, sx, "number")
    checkArg(3, sy, "number")
    checkArg(4, sw, "number")
    checkArg(5, sh, "number")
    checkArg(6, dx, "number")
    checkArg(7, dy, "number")
  end

  local sx0, sy0, sx1, sy1 = src:intersection(sx, sy, sw, sh)

  if not sx0 then
    return
  end

  local w = sx1 - sx0 + 1
  local h = sy1 - sy0 + 1

  local x0, y0, x1, y1 = self:intersection(dx, dy, w, h)

  if not x0 then
    return
  end

  sx0 = sx0 + (x0 - dx)
  sy0 = sy0 + (y0 - dy)
  w = x1 - x0 + 1
  h = y1 - y0 + 1

  local ix0, ix1, ixd = 1, w, 1
  local iy0, iy1, iyd = 1, h, 1

  if src == self then
    -- we're doing a self-to-self copy; don't mess up the source area

    if x0 < sx0 then
      ix0, ix1, ixd = 1, w, 1
    else
      ix0, ix1, ixd = w, 1, -1
    end

    if y0 < sy0 then
      iy0, iy1, iyd = 1, h, 1
    else
      iy0, iy1, iyd = h, 1, -1
    end
  end

  local lx, ly, rx, ry, char, fg, bg

  for x = ix0, ix1, ixd do
    for y = iy0, iy1, iyd do
      lx = x0 + x - 1
      ly = y0 + y - 1
      rx = sx0 + x - 1
      ry = sy0 + y - 1

      char, fg, bg = src:get(rx, ry)

      self:_set(lx, ly, fg, bg, 1, char)
    end
  end
end

--- Create a new buffer, and copy an area from self onto it.
-- @tparam[opt=1] int x0 the source area's top-left block column number
-- @tparam[opt=1] int y0 the source area's top-left block row number
-- @tparam int w the source area width
-- @tparam int h the source area height
-- @treturn[1] Buffer the cloned buffer
-- @treturn[2] nil width or height is less than 1
function Buffer:clone(x0, y0, w, h)
  if not (x0 and y0 and w and h) then
    -- 0 arguments
    x0, y0, w, h = 1, 1, self.w, self.h
  elseif x0 and y0 and not w and not h then
    -- 2 arguments
    x0, y0, w, h = 1, 1, x0, y0

    if self.debug then
      checkArg(1, w, "number")
      checkArg(2, h, "number")
    end
  elseif self.debug then
    checkArg(1, x0, "number")
    checkArg(2, y0, "number")
    checkArg(3, w, "number")
    checkArg(4, h, "number")
  end

  x0 = math.max(1, x0)
  y0 = math.max(1, y0)
  local x1 = math.min(x0 + self.w - 1, w)
  local y1 = math.min(y0 + self.h - 1, h)
  w = x1 - x0 + 1
  h = y1 - y0 + 1

  if w < 1 or h < 1 then
    return
  end

  local new = Buffer {w = w, h = h, depth = self.depth}
  local char, fg, bg

  for y = y0, y1, 1 do
    for x = x0, x1, 1 do
      char, fg, bg = self:get(x, y)
      new:_set(x, y, fg, bg, 1, char)
    end
  end

  return new
end

function Buffer:mergeDiff(x, y)
  local im, jm = self.storage:indexMain(x, y)
  local id, jd = self.storage:indexDiff(x, y)
  local char = self.storage.data[id][jd]
  local color = self.storage.data[id][jd + 1]

  if char then
    if char == " " then
      char = nil
    end

    self.storage.data[im][jm] = char
    self.storage.data[id][jd] = nil
  end

  if color then
    if color >= 0x1000000000000 then
      color = color % 0x1000000000000
      local bg = color % 0x1000000
      local fg = (color - bg) / 0x1000000
      color = (self.palette[self.palette:deflate(fg) + 1] * 0x1000000 +
               self.palette[self.palette:deflate(bg) + 1])
    end

    if color == self.defaultColor then
      color = nil
    end

    self.storage.data[im][jm + 1] = color
    self.storage.data[id][jd + 1] = nil
  end
end

---
-- @section end

--------------------------------------------------------------------------------

--- A flushable buffer.
local Framebuffer = class(Buffer, {name = "wonderful.buffer.Framebuffer"})

--- A flushable buffer.
-- @type Framebuffer

--- A buffer width.
-- @field Buffer.w

--- A buffer height.
-- @field Buffer.h

--- A palette the buffer uses.
-- @field Buffer.palette

--- A buffer depth.
-- @field Buffer.depth

--- Construct a new framebuffer.
-- @tparam table args a keyword argument table
-- @tparam int args.w a width of buffer
-- @tparam int args.h a height of buffer
-- @tparam int args.depth a color depth
-- @tparam boolean args.debug whether the debug mode should be set
function Framebuffer:__new__(args)
  self:superCall("__new__", args)

  self.dirty = {}

  self.blockSize = 16
  self.blocksW = math.ceil(self.w / self.blockSize)
  self.blocksH = math.ceil(self.h / self.blockSize)

  self:markForRedraw()
end

--- Check if a cell belongs to the buffer.
-- @tparam int x a row number
-- @tparam int y a row number
-- @treturn boolean
-- @see Buffer:inRange
-- @function Framebuffer:inRange

--- Perform alpha blending of two colors.
-- @tparam int color1 the first color
-- @tparam int color2 the second color
-- @tparam number alpha an opacity (an alpha value ∈ [0; 1])
-- @treturn int the result of alpha blending
-- @see Buffer:alphaBlend
-- @function Framebuffer:alphaBlend

--- Set a cell.
--
-- This is an internal method that **does not** perform sanity checks.
-- Futhermore, unlike @{wonderful.buffer.Framebuffer:set}, this method only sets
-- a single cell per call.
--
-- @tparam int x a column number
-- @tparam int y a row number
-- @tparam ?int fg a foreground color
-- @tparam ?int bg a background color
-- @tparam number alpha an opacity (an alpha value ∈ [0; 1])
-- @tparam ?string char a character
-- @see wonderful.buffer.Framebuffer:set
function Framebuffer:_set(x, y, fg, bg, alpha, char)
  local diff = 0

  do
    -- Copypasted from parent to avoid search costs
    local im, jm = self.storage:indexMain(x, y)
    local id, jd = self.storage:indexDiff(x, y)

    local mainChar = self.storage.data[im][jm]
    local mainColor = self.storage.data[im][jm + 1]
    local diffChar = self.storage.data[id][jd]
    local diffColor = self.storage.data[id][jd + 1]

    local old = diffColor or mainColor or self.defaultColor

    -- we don't care about the 49th bit here
    old = old % 0x1000000000000

    local oldBg = old % 0x1000000
    local oldFg = (old - oldBg) / 0x1000000

    if not fg and oldBg ~= oldFg then
      fg = oldFg
    end

    if alpha == 0 then
      fg = oldBg
      bg = oldBg
    elseif alpha == 1 then
      -- Don't change colors.
    else
      if char and oldBg ~= fg and fg then
        fg = self:alphaBlend(oldBg, fg, alpha)
      elseif not char and oldFg ~= fg and fg then
        fg = self:alphaBlend(oldFg, fg, alpha)
      end

      if oldBg ~= bg and bg then
        bg = self:alphaBlend(oldBg, bg, alpha)
      end
    end

    fg = fg or oldFg
    bg = bg or oldBg

    -- set: bytes 4-6 = fg
    --      bytes 1-3 = bg
    local new = fg * 0x1000000 + bg

    if new == (mainColor or self.defaultColor) then
      new = nil
    end

    -- set bit 49 (not reduced to palette)
    self.storage.data[id][jd + 1] = new and (new + 0x1000000000000)

    char = char or diffChar or mainChar or " "

    if char == (mainChar or " ") then
      char = nil
    end

    self.storage.data[id][jd] = char

    if diffChar or diffColor then
      if not (new or cchar) then
        -- Dirty block is made clean
        diff = -1
      end
    else
      if new or cchar then
        -- Clean block is made dirty
        diff = 1
      end
    end
  end

  local blockX = (x - 1) / self.blockSize
  blockX = blockX - blockX % 1

  local blockY = (y - 1) / self.blockSize
  blockY = blockY - blockY % 1

  local block = blockY * self.blocksW + blockX + 1

  self.dirty[block] = (self.dirty[block] or 0) + diff
end

--- Set a line of characters.
-- @tparam int x0 a column number
-- @tparam int y0 a row number
-- @tparam ?int fg a foreground color
-- @tparam ?int bg a background color
-- @tparam number alpha an opacity (an alpha value ∈ [0; 1])
-- @tparam ?string line a text line
-- @tparam[opt=false] boolean vertical if true, set a vertical line
-- @see wonderful.buffer.Framebuffer:_set
-- @see wonderful.buffer.Buffer:_set
-- @function Framebuffer:set

--- Retrieve a cell from the storage.
--
-- This is an internal method that **does not** perform sanity checks.
-- Futhermore, unlike @{wonderful.buffer.Framebuffer:get}, this method returns
-- a packed and deflated color instead of foreground and background.
--
-- @tparam int x a column number
-- @tparam int y a row number
-- @treturn string a cell's character
-- @treturn int a cell's packed and deflated color
-- @see wonderful.buffer.Framebuffer:get
-- @see wonderful.buffer.Buffer:_get
function Framebuffer:_get(x, y)
  local mainChar, mainColor = self.storage:getMain(x, y)
  local id, jd = self.storage:indexDiff(x, y)
  local diffChar = self.storage.data[id][jd]
  local diffColor = self.storage.data[id][jd + 1]

  -- reduce the color if the 49th bit is set
  if diffColor and diffColor >= 0x1000000000000 then
    diffColor = diffColor % 0x1000000000000
    local bg = diffColor % 0x1000000
    local fg = (diffColor - bg) / 0x1000000
    diffColor = (self.palette[self.palette:deflate(fg) + 1] * 0x1000000 +
                 self.palette[self.palette:deflate(bg) + 1])

    if diffColor == (mainColor or self.defaultColor) then
      diffColor = nil

      if not diffChar then
        -- the cell is clean now, decrement dirtiness

        local blockX = (x - 1) / self.blockSize
        blockX = blockX - blockX % 1

        local blockY = (y - 1) / self.blockSize
        blockY = blockY - blockY % 1

        local block = blockY * self.blocksW + blockX + 1

        -- this cannot be `nil`
        --                 \_________________
        self.dirty[block] = self.dirty[block] - 1
      end
    end

    self.storage.data[id][jd + 1] = diffColor
  end

  return diffChar or mainChar or " ",
         diffColor or mainColor or self.defaultColor
end

--- Retrieve a cell from the storage.
-- @tparam int x a column number
-- @tparam int y a row number
-- @treturn string a cell's character
-- @treturn int a cell's foreground color
-- @treturn int a cell's background color
-- @see wonderful.buffer.Framebuffer:_get
-- @see wonderful.buffer.Buffer:get
-- @function Framebuffer:get

--- Get an intersection of the buffer and a given sub-box.
-- @tparam int x0 a top-left cell column number
-- @tparam int y0 a top-left cell row number
-- @tparam int w a width of sub-box
-- @tparam int h a height of sub-box
-- @treturn[1] int an intersection's top-left cell column number
-- @treturn[1] int an intersection's top-left cell row number
-- @treturn[1] int an intersection's bottom-right cell column number
-- @treturn[1] int an intersection's bottom-right cell row number
-- @treturn[2] nil the intersection is empty
-- @see wonderful.buffer.Buffer:intersection
-- @function Framebuffer:intersection

--- Fill an area with a given cell.
--
-- This is an internal method that **does not** perform sanity checks.
--
-- @tparam int x0 a top-left cell column number
-- @tparam int y0 a top-left cell row number
-- @tparam int x1 a bottom-right cell column number
-- @tparam int y1 a bottom-right cell row number
-- @tparam ?int fg a foreground color
-- @tparam ?int bg a background color
-- @tparam number alpha an opacity (an alpha value ∈ [0; 1])
-- @tparam ?string char a character
-- @see wonderful.buffer.Buffer:fill
function Framebuffer:_fill(x0, y0, x1, y1, fg, bg, alpha, char)
  local blockSize = self.blockSize
  local storage = self.storage
  local indexMain = storage.indexMain
  local indexDiff = storage.indexDiff
  local storageData = storage.data
  local defaultColor = self.defaultColor
  local blocksW = self.blocksW
  local dirty = self.dirty

  local sdMain, sdDiff
  local oim, oid

  local blockX = (x0 - 1) / blockSize
  blockX = blockX - blockX % 1

  local blockY = (y0 - 1) / blockSize
  blockY = blockY - blockY % 1

  for y = y0, y1, 1 do
    if y ~= y0 and y % blockSize == 1 then
      -- crossed the chunk border
      blockY = blockY + 1
    end

    local block = blockY * blocksW + blockX + 1
    local blockDirtiness = dirty[block] or 0

    for x = x0, x1, 1 do
      if x ~= x0 and x % blockSize == 1 then
        -- crossed the chunk border
        dirty[block] = blockDirtiness
        block = block + 1
        blockDirtiness = dirty[block] or 0
      end

      local im, jm = indexMain(storage, x, y)
      local id, jd = indexDiff(storage, x, y)

      if oim ~= im then
        sdMain = storageData[im]
        oim = im
      end

      if oid ~= id then
        sdDiff = storageData[id]
        oid = id
      end

      local mainChar = sdMain[jm]
      local mainColor = sdMain[jm + 1]
      local diffChar = sdDiff[jd]
      local diffColor = sdDiff[jd + 1]

      local old = diffColor or mainColor or defaultColor

      -- we don't care about the 49th bit here
      old = old % 0x1000000000000

      local oldBg = old % 0x1000000
      local oldFg = (old - oldBg) / 0x1000000

      local cfg, cbg = fg, bg

      if not fg and oldBg ~= oldFg then
        cfg = oldFg
      end

      if alpha == 0 then
        cfg = oldBg
        cbg = oldBg
      elseif alpha < 1 then
        -- Don't change colors if alpha == 1
        if char and oldBg ~= cfg and cfg then
          cfg = self:alphaBlend(oldBg, cfg, alpha)
        elseif not char and oldFg ~= cfg and cfg then
          cfg = self:alphaBlend(oldFg, cfg, alpha)
        end

        if oldBg ~= cbg and cbg then
          cbg = self:alphaBlend(oldBg, cbg, alpha)
        end
      end

      cfg = cfg or oldFg
      cbg = cbg or oldBg

      -- set: bytes 4-6 = fg
      --      bytes 1-3 = bg
      local new = cfg * 0x1000000 + cbg

      if new == (mainColor or defaultColor) then
        new = nil
      end

      -- set bit 49 (not reduced to palette)
      sdDiff[jd + 1] = new and (new + 0x1000000000000)

      local cchar = char or diffChar or mainChar or " "

      if cchar == (mainChar or " ") then
        cchar = nil
      end

      sdDiff[jd] = cchar

      if diffChar or diffColor then
        if not (new or cchar) then
          -- Dirty block is made clean
          blockDirtiness = blockDirtiness - 1
        end
      else
        if new or cchar then
          -- Clean block is made dirty
          blockDirtiness = blockDirtiness + 1
        end
      end
    end

    dirty[block] = blockDirtiness
  end
end

--- Fill an area with a given cell.
-- @tparam int x0 a top-left cell column number
-- @tparam int y0 a top-left cell row number
-- @tparam int w an area width
-- @tparam int h an area width
-- @tparam ?int fg a foreground color
-- @tparam ?int bg a background color
-- @tparam number alpha an opacity (an alpha value ∈ [0; 1])
-- @tparam ?string char a character
-- @see wonderful.buffer.Framebuffer:_fill
-- @see wonderful.buffer.Buffer:fill
-- @function Framebuffer:fill

--- Reset all cells to default.
function Framebuffer:clear()
  self:superCall("clear")

  self:markForRedraw()
end

--- Redraw the whole buffer on next flush.
function Framebuffer:markForRedraw()
  for i = 1, self.blocksW * self.blocksH, 1 do
    self.dirty[i] = math.huge
  end
end

local function writeFillInstruction(instructions, textData, fills, x, y,
                                    char, color)
  local bg = color % 0x1000000
  local fg = (color - bg) / 0x1000000

  if not instructions[bg] then
    instructions[bg] = {}
    textData[bg] = {}
  end

  if not instructions[bg][fg] then
    instructions[bg][fg] = {}
    textData[bg][fg] = {}
  end

  if not fills[bg] then
    fills[bg] = {}
  end

  if not fills[bg][fg] then
    fills[bg][fg] = {}
  end

  local i = #instructions[bg][fg] + 1
  instructions[bg][fg][i] = x * 0x100 + y
  textData[bg][fg][i] = char
  fills[bg][fg][i] = true
end

local function writeLineInstruction(instructions, textData, lines,
                                    x, y, line, color)
  local bg = color % 0x1000000
  local fg = (color - bg) / 0x1000000

  if not instructions[bg] then
    instructions[bg] = {}
    textData[bg] = {}
  end

  if not instructions[bg][fg] then
    instructions[bg][fg] = {}
    textData[bg][fg] = {}
  end

  local yx = y * 0x100 + x
  local bgfg = bg * 0x1000000 + fg
  local len = unicode.wlen(line)

  if lines[yx] and lines[yx][1] == bgfg then
    local i = lines[yx][2]
    textData[bg][fg][i] = textData[bg][fg][i] .. line
    lines[yx] = nil
    lines[yx + len] = {bgfg, i}
  else
    local i = #instructions[bg][fg] + 1
    instructions[bg][fg][i] = x * 0x100 + y
    textData[bg][fg][i] = line
    lines[yx + len] = {bgfg, i}
  end
end

--- Flush a buffer onto a GPU.
-- @tparam int sx a top-left cell column number to draw buffer at
-- @tparam int sy a top-left cell row number to draw buffer at
-- @tparam table gpu GPU component proxy
function Framebuffer:flush(sx, sy, gpu)
  if self.debug then
    checkArg(1, sx, "number")
    checkArg(2, sy, "number")
    checkArg(3, gpu, "table")

    if gpu.type ~= "gpu" then
      error("bad argument #3: gpu proxy expected", 1)
    end
  end

  sx, sy = sx - 1, sy - 1

  local instructions = {}
  local textData = {}
  local fills = {}
  local lines = {}

  local blockX, blockY = 0, 0
  local blockI = 1

  local blockSize = self.blockSize

  local lastBlockX = (self.blocksW - 1) * blockSize
  local lastBlockY = (self.blocksH - 1) * blockSize

  local storage = self.storage
  local data = storage.data
  local indexMain = storage.indexMain
  local indexDiff = storage.indexDiff

  local palette = self.palette
  local mergeDiff = self.mergeDiff

  while true do
    local blockW = blockSize
    local blockH = blockW  -- blocks are square

    if blockX == lastBlockX then
      blockW = (self.w - 1) % blockSize + 1
    end

    if blockY == lastBlockY then
      blockH = (self.h - 1) % blockSize + 1
    end

    local dirtiness = self.dirty[blockI]

    if not dirtiness or dirtiness == 0 then
      goto continue
    end

    do
      local noForceProceed = dirtiness ~= math.huge

      local id, jd = indexDiff(storage, blockX + 1, blockY + 1)
      local rectChar = data[id][jd]
      local rectColor = data[id][jd + 1]

      -- reduce the color if the 49th bit is set
      if rectColor and rectColor >= 0x1000000000000 then
        rectColor = rectColor % 0x1000000000000
        local bg = rectColor % 0x1000000
        local fg = (rectColor - bg) / 0x1000000
        rectColor = (palette[palette:deflate(fg) + 1] * 0x1000000 +
                     palette[palette:deflate(bg) + 1])
        data[id][jd + 1] = rectColor
      end

      if not rectChar and not rectColor then
        goto notrect
      end

      if not rectChar or not rectColor then
        local i, j = indexMain(storage, blockX + 1, blockY + 1)
        rectChar = rectChar or data[i][j] or " "
        rectColor = rectColor or data[i][j + 1] or self.defaultColor
      end

      for x = blockX + 1, blockX + blockW do
        for y = blockY + 1, blockY + blockH do
          local id, jd = indexDiff(storage, x, y)
          local im, jm = indexMain(storage, x, y)
          local char = data[id][jd]
          local color = data[id][jd + 1]

          if color and color >= 0x1000000000000 then
            color = color % 0x1000000000000
            local bg = color % 0x1000000
            local fg = (color - bg) / 0x1000000
            color = (palette[palette:deflate(fg) + 1] * 0x1000000 +
                     palette[palette:deflate(bg) + 1])

            if color == (data[im][jd + 1] or self.defaultColor) then
              color = nil
            end

            storage.data[id][jd + 1] = color
          end

          if not (char or color) and noForceProceed then
            goto notrect
          end

          if not char or not color then
            char = char or data[im][jm] or " "
            color = color or data[im][jm + 1] or self.defaultColor
          end

          if char ~= rectChar or color ~= rectColor then
            goto notrect
          end
        end
      end

      do
        writeFillInstruction(instructions, textData, fills,
                             blockX, blockY, rectChar, rectColor)

        for x = blockX + 1, blockX + blockW do
          for y = blockY + 1, blockY + blockH do
            mergeDiff(self, x, y)
          end
        end

        goto continue
      end

      ::notrect::

      for y = blockY + 1, blockY + blockH do
        local lineX
        local line = {}
        local lineColor, lineBg

        for x = blockX + 1, blockX + blockW do
          local id, jd = indexDiff(storage, x, y)
          local im, jm = indexMain(storage, x, y)

          local char = data[id][jd]
          local color = data[id][jd + 1]

          if color and color >= 0x1000000000000 then
            color = color % 0x1000000000000
            local bg = color % 0x1000000
            local fg = (color - bg) / 0x1000000
            color = (palette[palette:deflate(fg) + 1] * 0x1000000 +
                     palette[palette:deflate(bg) + 1])

            if color == (data[im][jm + 1] or self.defaultColor) then
              color = nil
            end

            storage.data[id][jd + 1] = color
          end

          if not char and not color and noForceProceed then
            if #line > 0 then
              writeLineInstruction(instructions, textData, lines, lineX - 1,
                                   y - 1, table.concat(line), lineColor)
              line = {}
            end
          else
            if not char or not color then
              char = char or data[im][jm] or " "
              color = color or data[im][jm + 1] or self.defaultColor
            end

            if #line == 0 then
              lineColor = color
              lineBg = lineColor % 0x1000000
              lineX = x
            end

            local bg = color % 0x1000000

            if color == lineColor or (char == " " and bg == lineBg) then
              table.insert(line, char)
            else
              writeLineInstruction(instructions, textData, lines, lineX - 1,
                                   y - 1, table.concat(line), lineColor)

              lineX, lineColor, lineBg, line = x, color, bg, {char}
            end

            mergeDiff(self, x, y)
          end
        end

        if #line > 0 then
          writeLineInstruction(instructions, textData, lines, lineX - 1,
                               y - 1, table.concat(line), lineColor)
        end

      end
    end

    ::continue::

    blockX = blockX + blockSize
    blockI = blockI + 1

    if blockX == self.blocksW * blockSize then
      blockX = 0
      blockY = blockY + blockSize

      if blockY == self.blocksH * blockSize then
        break
      end
    end
  end

  for background, foregrounds in pairs(instructions) do
    gpu.setBackground(background)

    for foreground, chain in pairs(foregrounds) do
      gpu.setForeground(foreground)

      for i, pos in ipairs(chain) do
        local text = textData[background][foreground][i]
        local y = pos % 0x100
        local x = (pos - y) / 0x100

        if fills[background] and fills[background][foreground] and
            fills[background][foreground][i] then
          local width = math.min(blockSize, self.w - x)
          local height = math.min(blockSize, self.h - y)
          gpu.fill(sx + x + 1, sy + y + 1, width, height, text)
        else
          gpu.set(sx + x + 1, sy + y + 1, text)
        end
      end
    end
  end

  self.dirty = {}
end

--- Create a buffer view.
-- @tparam number x a coordinate box's top-left cell column number
-- @tparam number y a coordinate box's top-left cell row number
-- @tparam number w a coordinate box's width
-- @tparam number h a coordinate box's height
-- @tparam number sx a restricting box's top-left cell column number
-- @tparam number sy a restricting box's top-left cell row number
-- @tparam number sw a restricting box's width
-- @tparam number sh a restricting box's height
-- @treturn wonderful.buffer.BufferView
-- @see wonderful.buffer.Buffer:view
-- @function Framebuffer:view

--- Copy an area from a buffer and paste it onto self.
--
-- If the source area are omitted, the whole source buffer is copied.
--
-- @param src the source buffer to copy from
-- @tparam[opt] int sx the area's top-left cell column number
-- @tparam[optchain] int sy the area's top-left cell row number
-- @tparam[optchain] int sw the area width
-- @tparam[optchain] int sh the area height
-- @tparam int dx the column at which to paste the area's top-left cell
-- @tparam int dy the row at which to paste the area's top-left cell
-- @function Framebuffer:copyFrom

--- Create a new buffer, and copy an area from self onto it.
-- @tparam[opt=1] int x0 the source area's top-left block column number
-- @tparam[opt=1] int y0 the source area's top-left block row number
-- @tparam int w the source area width
-- @tparam int h the source area height
-- @treturn[1] Buffer the cloned buffer
-- @treturn[2] nil width or height is less than 1
-- @function Framebuffer:clone

---
-- @section end

--------------------------------------------------------------------------------

--- A view on some rectangular area within a buffer
BufferView = class(
  Buffer,
  {name = "wonderful.buffer.BufferView"}
)

--- A view on some rectangular area within a buffer
-- @type BufferView
-- @see Buffer:view

--- The buffer's depth.
-- @field BufferView.depth

--- The buffer's palette.
-- @field BufferView.palette

--- The view width.
-- @field BufferView.w

--- The view height
-- @field BufferView.h

--- Construct a view.
--
-- This method **should not** be used directly.
-- @see wonderful.buffer.Buffer:view
-- @see wonderful.buffer.Framebuffer:view
-- @see wonderful.buffer.BufferView:view
function BufferView:__new__(buf, coordBox, restrictBox, debug)
  self.buf = buf

  self.coordBox = coordBox
  self.box = restrictBox
  self.debug = debug
end

--- Convert view-relative coordinates to buffer-relative coordinates.
-- @tparam int x a view-relative cell column number
-- @tparam int y a view-relative cell row number
-- @treturn int a buffer-relative cell column number
-- @treturn int a buffer-relative cell row number
function BufferView:absCoords(x, y)
  if self.debug then
    checkArg(1, x, "number")
    checkArg(2, y, "number")
  end

  return x + self.coordBox.x - 1,
         y + self.coordBox.y - 1
end

--- Convert buffer-relative coordinates to view-relative coordinates.
-- @tparam int x a buffer-relative cell column number
-- @tparam int y a buffer-relative cell row number
-- @treturn int x a view-relative cell column number
-- @treturn int y a view-relative cell row number
function BufferView:relCoords(x, y)
  if self.debug then
    checkArg(1, x, "number")
    checkArg(2, y, "number")
  end
  return x - self.coordBox.x + 1,
         y - self.coordBox.y + 1
end

--- Check if a cell at given buffer-relative coordinates belongs to the view.
-- @tparam int x a view-relative cell column number
-- @tparam int y a view-relative cell row number
function BufferView:inRange(x, y)
  x, y = self:absCoords(x, y)

  return self.box:has(x, y)
end

--- Proxy @{wonderful.buffer.Buffer:_set} to the buffer.
-- @tparam int x a view-relative cell column number
-- @tparam int y a view-relative cell row number
-- @tparam ?int fg a foreground color
-- @tparam ?int bg a background color
-- @tparam number alpha an opacity (an alpha value ∈ [0; 1])
-- @tparam ?string char a character
-- @see wonderful.buffer.Buffer:_set
function BufferView:_set(x, y, fg, bg, alpha, char)
  x, y = self:absCoords(x, y)
  self.buf:_set(x, y, fg, bg, alpha, char)
end

--- Proxy @{wonderful.buffer.Buffer:_fill} to the buffer.
-- @tparam int x0 a view-relative top-left cell column number
-- @tparam int y0 a view-relative top-left cell row number
-- @tparam int x1 a view-relative bottom-right cell column number
-- @tparam int y1 a view-relative bottom-right cell row number
-- @tparam ?int fg a foreground color
-- @tparam ?int bg a background color
-- @tparam number alpha an opacity (an alpha value ∈ [0; 1])
-- @tparam ?string char a character
-- @see wonderful.buffer.Buffer:_fill
function BufferView:_fill(x0, y0, x1, y1, fg, bg, alpha, char)
  self.buf:_fill(x0, y0, x1, y1, fg, bg, alpha, char)
end

--- Proxy @{wonderful.buffer.Buffer:_get} to the buffer.
-- @tparam int x a view-relative cell column number
-- @tparam int y a view-relative cell row number
-- @treturn string a cell's character
-- @treturn int a cell's packed and deflated color
-- @see wonderful.buffer.Buffer:_get
function BufferView:_get(x, y)
  x, y = self:absCoords(x, y)

  return self.buf:_get(x, y)
end

--- Proxy @{wonderful.buffer.Buffer:intersection} to the buffer.
-- @tparam int x0 a view-relative top-left cell column number
-- @tparam int y0 a view-relative top-left cell row number
-- @tparam int w a sub-box width
-- @tparam int h a sub-box height
-- @treturn[1] int a buffer-relative intersection's top-left cell column number
-- @treturn[1] int a buffer-relative intersection's top-left cell row number
-- @treturn[1] int a buffer-relative intersection's bottom-right cell column number
-- @treturn[1] int a buffer-relative intersection's bottom-right cell row number
-- @treturn[2] nil the intersection is empty
-- @see wonderful.buffer.Buffer:intersection
function BufferView:intersection(x0, y0, w, h)
  if self.debug then
    checkArg(1, x0, "number")
    checkArg(2, y0, "number")
    checkArg(3, w, "number")
    checkArg(4, h, "number")
  end

  x0, y0 = self:absCoords(x0, y0)

  return self:superCall("intersection", x0, y0, w, h)
end

--- Create a view relative to the view.
--
-- The child view is bounded by the parent view's restricting box.
--
-- All coordinates are relative to the parent view's coordinate box.
--
-- The child view will point to the buffer directly.
-- @tparam int x a coordinate box's top-left cell column number
-- @tparam int y a coordinate box's top-left cell row number
-- @tparam int w a coordinate box's width
-- @tparam int h a cooridnate box's height
-- @tparam int sx a restricting box's top-left cell column number
-- @tparam int sy a restricting box's top-left cell row number
-- @tparam int sw a restricting box's width
-- @tparam int sh a restricting box's height
-- @treturn wonderful.buffer.BufferView
-- @see wonderful.buffer.Buffer:view
function BufferView:view(x, y, w, h, sx, sy, sw, sh)
  if self.debug then
    checkArg(1, x, "number")
    checkArg(2, y, "number")
    checkArg(3, w, "number")
    checkArg(4, h, "number")
    checkArg(5, sx, "number")
    checkArg(6, sy, "number")
    checkArg(7, sw, "number")
    checkArg(8, sh, "number")
  end

  local x, y = self:absCoords(x, y)

  local coordBox = geometry.Box(x, y, w, h)

  local restrictBox = self.coordBox:relative(sx, sy, sw, sh)
  restrictBox = restrictBox:intersection(self.box)
  restrictBox = restrictBox:intersection(coordBox)

  -- the `self.buf` here is why the method was copy-pasted from the parent:
  -- we don't really want to abuse recursion
  local view = BufferView(self.buf, coordBox, restrictBox)
  view:optimize()

  return view
end

--- Copy an area from a buffer and paste it onto self.
--
-- If the source area are omitted, the whole source buffer is copied.
--
-- @param src the source buffer to copy from
-- @tparam[opt] int sx the area's top-left cell column number
-- @tparam[optchain] int sy the area's top-left cell row number
-- @tparam[optchain] int sw the area width
-- @tparam[optchain] int sh the area height
-- @tparam int dx the column at which to paste the area's top-left cell
-- @tparam int dy the row at which to paste the area's top-left cell
-- @function BufferView:copyFrom

--- Create a new buffer, and copy an area from self onto it.
-- @tparam[opt=1] int x0 the source area's top-left block column number
-- @tparam[opt=1] int y0 the source area's top-left block row number
-- @tparam int w the source area width
-- @tparam int h the source area height
-- @treturn[1] Buffer the cloned buffer
-- @treturn[2] nil width or height is less than 1
-- @function BufferView:clone

function BufferView.__getters:depth()
  return self.buf.depth
end

function BufferView.__getters:palette()
  return self.buf.palette
end

function BufferView.__getters:w()
  return self.coordBox.w
end

function BufferView.__getters:h()
  return self.coordBox.h
end

---
-- @export
return {
  Buffer = Buffer,
  Framebuffer = Framebuffer,
  BufferView = BufferView,
}

