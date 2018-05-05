local unicode = require("unicode")

local class = require("lua-objects")

local geometry = require("wonderful.geometry")
local palette = require("wonderful.util.palette")

local storage

if _VERSION == "Lua 5.3" then
  storage = require("wonderful.buffer.storage53")
else
  storage = require("wonderful.buffer.storage52")
end

local Buffer = class(nil, {name = "wonderful.buffer.Buffer"})
local Framebuffer = class(Buffer, {name = "wonderful.buffer.Framebuffer"})
local BufferView = class(
  Buffer,
  {name = "wonderful.buffer.BufferView"}
)

function Buffer:__new__(args)
  self.w = args.w
  self.h = args.h
  self.depth = args.depth

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
    self.storage = storage.BufferStorageT1(self.w, self.h)
  elseif cells <= 50 * 25 then
    self.storage = storage.BufferStorageT2(self.w, self.h)
  elseif cells <= 160 * 50 then
    self.storage = storage.BufferStorageT3(self.w, self.h)
  else
    error(("Unsupported resolution: %d×%d"):format(self.w, self.h))
  end

  self.storage:optimize()

  self.defaultColor = self.palette:deflate(0xffffff) * 0x100 +
                      self.palette:deflate(0x000000)
end

function Buffer:inRange(x, y)
  return self.box:has(x, y)
end

function Buffer:alphaBlend(color1, color2, alpha)
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

function Buffer:_set(x, y, fg, bg, alpha, char)
  local im, jm, km = self.storage:indexMain(x, y)
  local id, jd, kd = self.storage:indexDiff(x, y)

  local mainChar = self.storage.data[im][jm][km]
  local mainColor = self.storage.data[im][jm][km + 1]
  local diffColor = self.storage.data[id][jd][kd + 1]

  local old = diffColor or mainColor or self.defaultColor

  local oldBg = self.palette:inflate(old % 0x100)

  fg = self.palette:deflate(self:alphaBlend(oldBg, fg, alpha))
  bg = self.palette:deflate(self:alphaBlend(oldBg, bg, alpha))

  local new = fg * 0x100 + bg

  if new == mainColor then
    new = nil
  end

  if char == mainChar then
    char = nil
  end

  self.storage.data[id][jd][kd] = char
  self.storage.data[id][jd][kd + 1] = new

  return new ~= mainColor or char ~= mainChar
end

function Buffer:set(x0, y0, fg, bg, alpha, line, vertical)
  checkArg(1, x0, "number")
  checkArg(2, y0, "number")
  checkArg(3, fg, "number")
  checkArg(4, bg, "number")
  checkArg(5, alpha, "number")
  checkArg(6, line, "string")

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
end

function Buffer:_get(x, y)
  local mainChar, mainColor = self.storage:getMain(x, y)
  local diffChar, diffColor = self.storage:getDiff(x, y)

  return diffChar or mainChar or " ",
         diffColor or mainColor or self.defaultColor
end

function Buffer:get(x, y)
  checkArg(1, x, "number")
  checkArg(2, y, "number")

  if not self:inRange(x, y) then
    return false
  end

  local char, color = self:_get(x, y)

  return char,
         self.palette:inflate((color - color % 100) / 0x100),
         self.palette:inflate(color % 0x100)
end

function Buffer:intersection(x0, y0, w, h)
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

function Buffer:fill(x0, y0, w, h, fg, bg, alpha, char)
  checkArg(1, x0, "number")
  checkArg(2, y0, "number")
  checkArg(3, w, "number")
  checkArg(4, h, "number")
  checkArg(5, fg, "number")
  checkArg(6, bg, "number")
  checkArg(7, alpha, "number")
  checkArg(8, char, "string")

  local x0, y0, x1, y1 = self:intersection(x0, y0, w, h)

  if not x0 then
    return
  end

  for x = x0, x1, 1 do
    for y = y0, y1, 1 do
      self:_set(x, y, fg, bg, alpha, char)
    end
  end
end

function Buffer:clear()
  self.storage:clear()
end

function Buffer:view(x, y, w, h, sx, sy, sw, sh)
  -- defines the view (buffer-relative) coordinate system
  local coordBox = geometry.Box(x, y, w, h)

  -- restricts the view
  local restrictBox = geometry.Box(sx, sy, sw, sh)

  -- don't allow to write outside the buffer
  restrictBox = restrictBox:intersection(self.box)

  -- don't allow to write outside the coordinate box
  restrictBox = restrictBox:intersection(coordBox)

  local view = BufferView(self, coordBox, restrictBox)
  view:optimize()

  return view
end

--------------------------------------------------------------------------------

function Framebuffer:__new__(args)
  self:superCall("__new__", args)

  self.dirty = {}

  self.blockSize = 10
  self.blocksW = math.ceil(self.w / self.blockSize)
  self.blocksH = math.ceil(self.h / self.blockSize)

  self:markForRedraw()
end

function Framebuffer:_set(x, y, fg, bg, alpha, char)
  local diff = self:superCall("_set", x, y, fg, bg, alpha, char)

  local blockX = (y - 1) / self.blockSize
  -- floor
  blockX = blockX - blockX % 1

  local blockY = x / self.blockSize
  -- ceil
  if blockY ~= blockY % 1 then
    blockY = blockY + (1 - blockY % 1)
  end

  local block = blockX * self.blocksW + blockY

  self.dirty[block] = (self.dirty[block] or 0) + (diff and 1 or -1)
end

function Framebuffer:clear()
  self:superCall("clear")

  self:markForRedraw()
end

function Framebuffer:markForRedraw()
  for i = 1, self.blocksW * self.blocksH, 1 do
    self.dirty[i] = math.huge
  end
end

local function writeFillInstruction(instructions, textData, fills, x, y,
                                    char, color)
  local fg, bg = (color - color % 0x100) / 0x100, color % 0x100

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
  local fg, bg = (color - color % 0x100) / 0x100, color % 0x100

  if not instructions[bg] then
    instructions[bg] = {}
    textData[bg] = {}
  end

  if not instructions[bg][fg] then
    instructions[bg][fg] = {}
    textData[bg][fg] = {}
  end

  local yx = y * 0x100 + x
  local bgfg = bg * 0x100 + fg
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

function Framebuffer:flush(sx, sy, gpu)
  sx, sy = sx - 1, sy - 1

  local instructions = {}
  local textData = {}
  local fills = {}
  local lines = {}

  local blockX, blockY = 0, 0
  local blockI = 1

  while true do
    local blockW, blockH = self.blockSize, self.blockSize

    if blockX == self.blocksW - 1 then
      blockW = self.w % self.blockSize
    end

    if blockY == self.blocksH - 1 then
      blockH = self.h % self.blockSize
    end

    if self.dirty[blockI] == 0 then
      goto continue
    end

    do
      local rectChar, rectColor = self:_get(blockX + 1, blockY + 1)
      local rect = true

      for x = blockX + 1, blockX + blockW do
        for y = blockY + 1, blockY + blockH do
          local char, color = self:_get(x, y)

          if char ~= rectChar or color ~= rectColor then
            rect = false
            break
          end
        end
      end

      if rect then
        writeFillInstruction(instructions, textData, fills,
                             blockX, blockY, rectChar, rectColor)
        goto continue
      end

      for y = blockY + 1, blockY + blockH do
        local lineX = blockX + 1
        local line = {}
        local _, lineColor = self:_get(blockX + 1, y)
        local lineBg = lineColor % 0x100

        for x = blockX + 1, blockX + blockW do
          local char, color = self:_get(x, y)
          local bg = color % 0x100

          if color == lineColor or (char == " " and bg == lineBg) then
            table.insert(line, char)
          else
            writeLineInstruction(instructions, textData, lines, lineX - 1,
                                 y - 1, table.concat(line), lineColor)
            lineX, lineColor, lineBg, line = x, color, bg, {char}
          end
        end

        if #line > 0 then
          writeLineInstruction(instructions, textData, lines, lineX - 1,
                               y - 1, table.concat(line), lineColor)
        end
      end
    end

    ::continue::

    blockX = blockX + self.blockSize
    blockI = blockI + 1

    if blockX == self.blocksW * self.blockSize then
      blockX = 0
      blockY = blockY + self.blockSize

      if blockY == self.blocksH * self.blockSize then
        break
      end
    end
  end

  for background, foregrounds in pairs(instructions) do
    gpu.setBackground(self.palette:inflate(background))

    for foreground, chain in pairs(foregrounds) do
      gpu.setForeground(self.palette:inflate(foreground))

      for i, pos in ipairs(chain) do
        local text = textData[background][foreground][i]
        local y = pos % 0x100
        local x = (pos - y) / 0x100

        if fills[background] and fills[background][foreground] and
            fills[background][foreground][i] then
          local width = math.min(self.blockSize, self.w - x)
          local height = math.min(self.blockSize, self.h - y)
          gpu.fill(sx + x + 1, sy + y + 1, width, height, text)
        else
          gpu.set(sx + x + 1, sy + y + 1, text)
        end
      end
    end
  end

  self.dirty = {}
end

--------------------------------------------------------------------------------

function BufferView:__new__(buf, coordBox, restrictBox)
  self.buf = buf

  self.coordBox = coordBox
  self.box = restrictBox
end

function BufferView:absCoords(x, y)
  return x + self.coordBox.x - 1,
         y + self.coordBox.y - 1
end

function BufferView:relCoords(x, y)
  return x - self.coordBox.x + 1,
         y - self.coordBox.y + 1
end

function Buffer:inRange(x, y)
  x, y = self:absCoords(x, y)

  return self.box:has(x, y)
end

function BufferView:_set(x, y, fg, bg, alpha, char)
  x, y = self:absCoords(x, y)
  self.buf:_set(x, y, fg, bg, alpha, char)
end

function BufferView:_get(x, y)
  x, y = self:absCoords(x, y)

  return self.buf:_get(x, y)
end

function BufferView:intersection(x0, y0, w, h)
  x0, y0 = self:absCoords(x0, y0)

  local x0, y0, x1, y1 = self:superCall("intersection", x0, y0, w, h)

  if not x0 then
    return
  end

  x0, y0 = self:relCoords(x0, y0)
  x1, y1 = self:relCoords(x1, y1)

  return x0, y0, x1, y1
end

function BufferView:view(x, y, w, h, sx, sy, sw, sh)
  local x, y = self:absCoords(x, y)

  local coordBox = geometry.Box(x, y, w, h)

  local restrictBox = coordBox:relative(sx, sy, sw, sh)
  restrictBox = restrictBox:intersection(self.box)
  restrictBox = restrictBox:intersection(coordBox)

  -- the `self.buf` here is why the method was copy-pasted from the parent:
  -- we don't really want to abuse recursion
  local view = BufferView(self.buf, coordBox, restrictBox)
  view:optimize()

  return view
end

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

return {
  Buffer = Buffer,
  Framebuffer = Framebuffer,
  BufferView = BufferView,
}

