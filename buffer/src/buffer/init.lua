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
local paletteUtil = require("wonderful.util.palette")

local storageMod

if _VERSION == "Lua 5.3" then
  storageMod = require("wonderful.buffer.storage53")
else
  storageMod = require("wonderful.buffer.storage52")
end

--- An enum of flush instruction types.
local InstructionTypes = {
  Set = 0x000000000,  -- the set instruction
}

--- A non-renderable buffer.
local Buffer = class(nil, {name = "wonderful.buffer.Buffer"})

local BufferView

--- A non-renderable buffer.
-- @type Buffer

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
-- @tparam[opt=0xffffff] int args.defaultFg the default foreground color
-- @tparam[opt=0x000000] int args.defaultBg the default background color
function Buffer:__new__(args)
  self._w = args.w
  self._h = args.h
  self._depth = args.depth

  if args.debug == nil then
    self._debug = true
  else
    self._debug = not not args.debug
  end

  self._box = geometry.Box(1, 1, self._w, self._h)

  if self._depth == 1 then
    self._palette = paletteUtil.t1
  elseif self._depth == 4 then
    self._palette = paletteUtil.t2
  elseif self._depth == 8 then
    self._palette = paletteUtil.t3
  end

  local cells = self._w * self._h

  if cells <= 25 * 16 then
    self._storage = storageMod.BufferStorageT1(self._w, self._h)
  elseif cells <= 50 * 25 then
    self._storage = storageMod.BufferStorageT2(self._w, self._h)
  elseif cells <= 160 * 50 then
    self._storage = storageMod.BufferStorageT3(self._w, self._h)
  else
    error(("Unsupported resolution: %d×%d"):format(self._w, self._h))
  end

  self._storage:optimize()

  self._defaultColor = (args.defaultFg or 0xffffff) * 0x1000000 +
                       (args.defaultBg or 0x000000)
end

function Buffer:getWidth()
  return self._w
end

function Buffer:getHeight()
  return self._h
end

function Buffer:getDepth()
  return self._depth
end

function Buffer:getPalette()
  return self._palette
end

--- Check if a cell belongs to the buffer.
-- @tparam int x a row number
-- @tparam int y a row number
-- @treturn boolean
function Buffer:inRange(x, y)
  if self._debug then
    checkArg(1, x, "number")
    checkArg(2, y, "number")
  end

  return self._box:has(x, y)
end

--- Perform alpha blending of two colors.
-- @tparam int color1 the first color
-- @tparam int color2 the second color
-- @tparam number alpha an opacity (an alpha value ∈ [0; 1])
-- @treturn int the result of alpha blending
function Buffer:alphaBlend(color1, color2, alpha)
  if self._debug then
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

  local r1, g1, b1 = paletteUtil.extract(color1)
  local r2, g2, b2 = paletteUtil.extract(color2)

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
  local storage = self._storage
  local im, jm = storage:indexMain(x, y)
  local id, jd = storage:indexDiff(x, y)

  local mainChar = storage.data[im][jm]
  local mainColor = storage.data[im][jm + 1]
  local diffColor = storage.data[id][jd + 1]

  local old = diffColor or mainColor or self._defaultColor

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
  elseif alpha < 1 then
    -- Don't change colors if alpha == 1.

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

  if new == (mainColor or self._defaultColor) then
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
  if self._debug then
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
    self:_set(x0, y0, fg, bg, alpha, nil)
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
  local mainChar, mainColor = self._storage:getMain(x, y)
  local id, jd = self._storage:indexDiff(x, y)
  local diffChar = self._storage.data[id][jd]
  local diffColor = self._storage.data[id][jd + 1]

  -- reduce the color if the 49th bit is set
  if diffColor and diffColor >= 0x1000000000000 then
    diffColor = diffColor % 0x1000000000000
    local bg = diffColor % 0x1000000
    local fg = (diffColor - bg) / 0x1000000
    diffColor = (self._palette[self._palette:deflate(fg) + 1] * 0x1000000 +
                 self._palette[self._palette:deflate(bg) + 1])

    if diffColor == (mainColor or self._defaultColor) then
      diffColor = nil
    end

    self._storage.data[id][jd + 1] = diffColor
  end

  return diffChar or mainChar or " ",
         diffColor or mainColor or self._defaultColor
end

--- Retrieve a cell from the storage.
-- @tparam int x a column number
-- @tparam int y a row number
-- @treturn string a cell's character
-- @treturn int a cell's foreground color
-- @treturn int a cell's background color
-- @see wonderful.buffer.Buffer:_get
function Buffer:get(x, y)
  if self._debug then
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
  if self._debug then
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

  if x1 < self._box.x or y1 < self._box.y then
    return
  end

  x0 = math.max(x0, self._box.x)
  y0 = math.max(y0, self._box.y)
  x1 = math.min(x1, self._box.x1)
  y1 = math.min(y1, self._box.y1)

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
  local storage = self._storage
  local indexMain = storage.indexMain
  local indexDiff = storage.indexDiff
  local storageData = storage.data
  local defaultColor = self._defaultColor

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
  if self._debug then
    checkArg(1, x0, "number")
    checkArg(2, y0, "number")
    checkArg(3, w, "number")
    checkArg(4, h, "number")
    checkArg(5, fg, "number", "nil")
    checkArg(6, bg, "number", "nil")
    checkArg(7, alpha, "number")
    checkArg(8, char, "string", "nil")
  end

  local x1, y1

  x0, y0, x1, y1 = self:intersection(x0, y0, w, h)

  if not x0 then
    return
  end

  char = char and unicode.sub(char, 1, 1) or nil

  self:_fill(x0, y0, x1, y1, fg, bg, alpha, char)
end

--- Reset all cells to default.
function Buffer:clear()
  local bg = self._defaultColor % 0x1000000
  local fg = (self._defaultColor - bg) / 0x1000000
  self._storage:_fill(1, 1, self._w, self._h, fg, bg, 1, " ")
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
  if self._debug then
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
  restrictBox = restrictBox:intersection(self._box)

  -- don't allow to write outside the coordinate box
  restrictBox = restrictBox:intersection(coordBox)

  local view = BufferView(self, coordBox, restrictBox, self._debug)
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
  if self._debug then
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

  if self._debug then
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
    x0, y0, w, h = 1, 1, self._w, self._h
  elseif x0 and y0 and not w and not h then
    -- 2 arguments
    x0, y0, w, h = 1, 1, x0, y0

    if self._debug then
      checkArg(1, w, "number")
      checkArg(2, h, "number")
    end
  elseif self._debug then
    checkArg(1, x0, "number")
    checkArg(2, y0, "number")
    checkArg(3, w, "number")
    checkArg(4, h, "number")
  end

  x0 = math.max(1, x0)
  y0 = math.max(1, y0)
  local x1 = math.min(x0 + self._w - 1, w)
  local y1 = math.min(y0 + self._h - 1, h)
  w = x1 - x0 + 1
  h = y1 - y0 + 1

  if w < 1 or h < 1 then
    return
  end

  local new = Buffer {w = w, h = h, depth = self._depth}
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
  local storage = self._storage
  local data = storage.data

  local im, jm = storage:indexMain(x, y)
  local id, jd = storage:indexDiff(x, y)
  local char = data[id][jd]
  local color = data[id][jd + 1]

  if char then
    if char == " " then
      char = nil
    end

    data[im][jm] = char
    data[id][jd] = nil
  end

  if color then
    if color >= 0x1000000000000 then
      color = color % 0x1000000000000
      local bg = color % 0x1000000
      local fg = (color - bg) / 0x1000000
      color = (self._palette[self._palette:deflate(fg) + 1] * 0x1000000 +
               self._palette[self._palette:deflate(bg) + 1])
    end

    if color == self._defaultColor then
      color = nil
    end

    data[im][jm + 1] = color
    data[id][jd + 1] = nil
  end
end

--- @section end

--------------------------------------------------------------------------------

--- A flushable buffer.
local Framebuffer = class(Buffer, {name = "wonderful.buffer.Framebuffer"})

--- A flushable buffer.
-- @type Framebuffer

--- Construct a new framebuffer.
-- @tparam table args a keyword argument table
-- @tparam int args.w a width of buffer
-- @tparam int args.h a height of buffer
-- @tparam int args.depth a color depth
-- @tparam boolean args.debug whether the debug mode should be set
function Framebuffer:__new__(args)
  self:superCall("__new__", args)

  self._dirty = {}

  -- used when compiling flush instructions
  self._instructions = {}
  self._textData = {}
  self._colorData = {}

  self._forceRedraw = true
end

--- Write a render instruction.
--
-- Used by `flush` when compiling render instructions.
--
-- @param itype one of `InstructionTypes` variants
-- @tparam int x a 0-based column number
-- @tparam int y a 0-based row number
-- @tparam int color a packed color (`(fg << 24) | bg`)
-- @tparam string text a char for fills, or a line for sets
function Framebuffer:writeInstruction(itype, x, y, color, text)
  local instructions = self._instructions
  local textData = self._textData
  local colorData = self._colorData

  local instrIndex = #instructions + 1
  local yx = y * 0x100 + x
  local index = yx

  instructions[instrIndex] = (itype +
                              yx * 0x10000 +
                              index)
  textData[index] = text
  colorData[index] = color
end

--- Compile GPU instructions to render the changes onto a GPU.
--
-- Used by `flush`.
--
-- @tparam boolean force whether to do force-redraw
function Framebuffer:compileInstructions(force)
  local noForceProceed = not force

  local storage = self._storage
  local data = storage.data
  local indexMain = storage.indexMain
  local indexDiff = storage.indexDiff

  local palette = self._palette
  local deflate = self._palette.deflate

  local mergeDiff = self._mergeDiff
  local writeInstruction = self._writeInstruction

  local tconcat = table.concat

  local Set = InstructionTypes.Set

  for y = 1, self._h, 1 do
    local lineX  -- where the line starts
    local line = {}  -- the line itself (a sequence of characters)
    local lineColor, lineBg  -- the packed color and extracted background

    for x = 1, self._w, 1 do
      local id, jd = indexDiff(storage, x, y)
      local im, jm = indexMain(storage, x, y)

      local char = data[id][jd]
      local color = data[id][jd + 1]

      if color and color >= 0x1000000000000 then
        color = color % 0x1000000000000
        local bg = color % 0x1000000
        local fg = (color - bg) / 0x1000000
        color = (palette[deflate(palette, fg) + 1] * 0x1000000 +
                 palette[deflate(palette, bg) + 1])

        if color == (data[im][jm + 1] or self._defaultColor) then
          color = nil
        end

        data[id][jd + 1] = color
      end

      if not char and not color and noForceProceed then
        -- the cell wasn't changed; write the line if it's non-empty

        if #line > 0 then
          writeInstruction(self, Set, lineX - 1, y - 1,
                           lineColor, tconcat(line))
          -- preallocate array to 8 elements
          line = {nil, nil, nil, nil, nil, nil, nil, nil}
        end
      else
        if not char then
          char = data[im][jm] or " "
        end

        if not color then
          color = data[im][jm + 1] or self._defaultColor
        end

        -- if #line == 0, the line parameters aren't set yet
        if #line == 0 then
          lineColor = color
          lineBg = lineColor % 0x1000000
          lineX = x
        end

        local bg = color % 0x1000000

        if color == lineColor or (char == " " and bg == lineBg) then
          -- extend the line
          line[#line + 1] = char
        else
          -- write the instruction, and start a new line
          writeInstruction(self, Set, lineX - 1, y - 1,
                           lineColor, tconcat(line))

          lineX, lineColor, lineBg = x, color, bg
          line = {char, nil, nil, nil, nil, nil, nil, nil}
        end

        mergeDiff(self, x, y)
      end
    end

    if #line > 0 then
      writeInstruction(self, InstructionTypes.Set, lineX - 1, y - 1,
                       lineColor, tconcat(line))
    end
  end
end

--- Flush a buffer onto a GPU.
--
-- The 4th argument, force, controls whether the buffer should also flush the
-- cells unchanged since the last flush.
--
-- @tparam int sx a top-left cell column number to draw buffer at
-- @tparam int sy a top-left cell row number to draw buffer at
-- @tparam table gpu GPU component proxy
-- @tparam[opt] boolean force whether to do force-redraw
function Framebuffer:flush(sx, sy, gpu, force)
  if self._debug then
    checkArg(1, sx, "number")
    checkArg(2, sy, "number")
    checkArg(3, gpu, "table")
    checkArg(4, force, "boolean", "nil")

    if gpu.type ~= "gpu" then
      error("bad argument #3: gpu proxy expected", 1)
    end
  end

  sx, sy = sx - 1, sy - 1

  self:compileInstructions(force or self._forceRedraw)

  local colorData = self._colorData
  local textData = self._textData

  -- group the instructions by the color to decrease the number of
  -- gpu.setBackground calls
  table.sort(self._instructions, function(lhs, rhs)
    return colorData[lhs % 0x10000] < colorData[rhs % 0x10000]
  end)

  local gbg = gpu.getBackground()
  local gfg = gpu.getForeground()

  local index, yx, itype, x, y, color, fg, bg, text

  for _, instruction in ipairs(self._instructions) do
    -- instruction = [type: 1 byte] [y: 1 byte] [x: 1 byte] [index: 2 bytes]
    -- self._colorData[index] returns the color data ((fg << 24) | bg)
    -- self._textData[index] returns the line (for set) or the char (for fill)
    --
    -- Also, keep in mind that x and y here are 0-based.
    --
    -- As we definitely don't want to use `bit32` here, we do a few %'s and /'s
    -- instead.

    index = instruction % 0x10000  -- instruction & 0xffff
    yx = (instruction - index) % 0x100000000  -- instruction & 0xffff0000
    itype = instruction - yx - index  -- instruction & 0xff00000000
    yx = yx / 0x10000  -- yx >> 16
    x = yx % 0x100  -- yx & 0xff
    y = (yx - x) / 0x100  -- yx >> 16
    color = colorData[index]
    text = textData[index]
    bg = color % 0x1000000  -- color & 0xffffff
    fg = (color - bg) / 0x1000000  -- color >> 24

    if gbg ~= bg then
      gpu.setBackground(bg)
      gbg = bg
    end

    if gfg ~= fg then
      gpu.setForeground(fg)
      gfg = fg
    end

    if itype == InstructionTypes.Set then
      gpu.set(sx + x + 1, sy + y + 1, text)
    end
  end

  self._instructions = {}
  self._textData = {}
  self._colorData = {}
  self._forceRedraw = false
end

--- @section end

--------------------------------------------------------------------------------

--- A view on some rectangular area within a buffer
BufferView = class(
  Buffer,
  {name = "wonderful.buffer.BufferView"}
)

--- A view on some rectangular area within a buffer
-- @type BufferView

--- Construct a view.
--
-- This method **should not** be used directly.
-- @see wonderful.buffer.Buffer:view
-- @see wonderful.buffer.BufferView:view
function BufferView:__new__(buf, coordBox, restrictBox, debug)
  self._buf = buf

  self._coordBox = coordBox
  self._box = restrictBox
  self._debug = debug
end

--- Convert view-relative coordinates to buffer-relative coordinates.
-- @tparam int x a view-relative cell column number
-- @tparam int y a view-relative cell row number
-- @treturn int a buffer-relative cell column number
-- @treturn int a buffer-relative cell row number
function BufferView:absCoords(x, y)
  if self._debug then
    checkArg(1, x, "number")
    checkArg(2, y, "number")
  end

  return x + self._coordBox.x - 1,
         y + self._coordBox.y - 1
end

--- Convert buffer-relative coordinates to view-relative coordinates.
-- @tparam int x a buffer-relative cell column number
-- @tparam int y a buffer-relative cell row number
-- @treturn int x a view-relative cell column number
-- @treturn int y a view-relative cell row number
function BufferView:relCoords(x, y)
  if self._debug then
    checkArg(1, x, "number")
    checkArg(2, y, "number")
  end
  return x - self._coordBox.x + 1,
         y - self._coordBox.y + 1
end

--- Check if a cell at given buffer-relative coordinates belongs to the view.
-- @tparam int x a view-relative cell column number
-- @tparam int y a view-relative cell row number
function BufferView:inRange(x, y)
  x, y = self:absCoords(x, y)

  return self._box:has(x, y)
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
  self._buf:_set(x, y, fg, bg, alpha, char)
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
  self._buf:_fill(x0, y0, x1, y1, fg, bg, alpha, char)
end

--- Proxy @{wonderful.buffer.Buffer:_get} to the buffer.
-- @tparam int x a view-relative cell column number
-- @tparam int y a view-relative cell row number
-- @treturn string a cell's character
-- @treturn int a cell's packed and deflated color
-- @see wonderful.buffer.Buffer:_get
function BufferView:_get(x, y)
  x, y = self:absCoords(x, y)

  return self._buf:_get(x, y)
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
  if self._debug then
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
  if self._debug then
    checkArg(1, x, "number")
    checkArg(2, y, "number")
    checkArg(3, w, "number")
    checkArg(4, h, "number")
    checkArg(5, sx, "number")
    checkArg(6, sy, "number")
    checkArg(7, sw, "number")
    checkArg(8, sh, "number")
  end

  x, y = self:absCoords(x, y)

  local coordBox = geometry.Box(x, y, w, h)

  local restrictBox = self._coordBox:relative(sx, sy, sw, sh)
  restrictBox = restrictBox:intersection(self._box)
  restrictBox = restrictBox:intersection(coordBox)

  -- the `self._buf` here is why the method was copy-pasted from the parent:
  -- we don't really want to abuse recursion
  local view = BufferView(self._buf, coordBox, restrictBox)
  view:optimize()

  return view
end

function BufferView:getDepth()
  return self._buf:getDepth()
end

function BufferView:getPalette()
  return self._buf:getPalette()
end

function BufferView:getWidth()
  return self._coordBox:getWidth()
end

function BufferView:getHeight()
  return self._coordBox:getHeight()
end

--- @export
return {
  Buffer = Buffer,
  Framebuffer = Framebuffer,
  BufferView = BufferView,
}

