local class = require("lua-objects")

local util = require("wonderful.util")

local floor = math.floor

local CellDiff = {
  None = 0,  -- no difference
  Char = 1,  -- different character, same color
  Color = 2,  -- different color
}

local function channels(color)
  return floor(color / 0x10000),
         floor((color % 0x10000) / 0x100),
         color % 0x100
end

local Buffer = class(nil, {name = "wonderful.buffer.Buffer"})
local BufferView = class(Buffer, {name = "wonderful.buffer:BufferView"})

function Buffer:__new__(args)
  self.w = args.w
  self.h = args.h
  self.depth = args.depth
  self.cells = {}
  if self.depth == 1 then
    self.palette = util.palette.t1
  elseif self.depth == 4 then
    self.palette = util.palette.t2
  elseif self.depth == 8 then
    self.palette = util.palette.t3
  end
  self.defaultFg = self:approximate(0xffffff)
  self.defaultBg = self:approximate(0x000000)
end

function Buffer:index(x, y)
  return self.w * (y - 1) + 3 * (x - 1) + 1
end

function Buffer:coords(index)
  local i = (index - 1) / 3
  local y = floor(i / self.w) + 1
  local x = floor(i) % self.w + 1
  return x, y
end

function Buffer:inRange(x, y)
  return x >= 1 and x <= self.w and y >= 1 and y <= self.h
end

function Buffer:rectInRange(x, y, w, h)
  return x >= 1 and x <= self.w and
         y >= 1 and y <= self.h and
         w >= 1 and x + w - 1 <= self.w and
         h >= 1 and y + h - 1 <= self.h
end

function Buffer:approximate(color)
  return self.palette:inflate(self.palette:deflate(color))
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
  local r1, g1, b1 = channels(color1)
  local r2, g2, b2 = channels(color2)
  local ialpha = 1 - alpha
  return floor(r1 * ialpha + r2 * alpha + 0.5) * 0x10000 +
         floor(g1 * ialpha + g2 * alpha + 0.5) * 0x100 +
         floor(b1 * ialpha + b2 * alpha + 0.5)
end

function Buffer:set(x, y, fg, bg, alpha, char)
  if not self:inRange(x, y) then
    return false
  end
  local i = self:index(x, y)

  local cfg = self.cells[i]
  fg = self:approximate(self:alphaBlend(cfg, fg, alpha))
  if fg == self.defaultFg then
    fg = nil
  end

  local cbg = self.cells[i + 1]
  bg = self:approximate(self:alphaBlend(cbg, bg, alpha))
  if bg == self.defaultBg then
    bg = nil
  end

  if char == " " then
    char = nil
  end

  self.cells[i] = fg
  self.cells[i + 1] = bg
  self.cells[i + 2] = char
end

function Buffer:get(x, y)
  if not self:inRange(x, y) then
    return false
  end
  local i = self:index(x, y)

  -- char, fg, bg
  local char, fg, bg = self.cells[i + 2], self.cells[i], self.cells[i + 1]

  if not char then
    char = " "
  end

  if not fg then
    fg = self.defaultFg
  end

  if not bg then
    bg = self.defaultBg
  end

  return char, fg, bg
end

function Buffer:fill(x0, y0, w, h, fg, bg, alpha, char)
  for x = x0, x0 + w - 1, 1 do
    for y = y0, y0 + h - 1, 1 do
      self:set(x, y, fg, bg, alpha, char)
    end
  end
end

function Buffer:view(x, y, w, h)
  if not self:rectInRange(x, y, w, h) then
    return false
  end
  return BufferView(self, x, y, w, h)
end

function Buffer:clear()
  self.cells = {}
end

function Buffer:copyFrom(buf)
  if buf.w ~= self.w or buf.h ~= buf.h or buf.depth ~= self.depth then
    error("Buffers have different geometry and/or depth")
  end
  for x = 1, self.w, 1 do
    for y = 1, self.h, 1 do
      local char, fg, bg = buf:get(x, y)
      self:set(x, y, fg, bg, 1, char)
    end
  end
end

--------------------------------------------------------------------------------

function BufferView:__new__(buffer, x, y, w, h)
  self.buffer = buffer
  self.x = x
  self.y = y
  self.w = w
  self.h = h
end

-- Converts view-relative coords to buffer-relative coords
function BufferView:absCoords(x, y)
  return x + self.x - 1,
         y + self.y - 1
end

function BufferView:set(x, y, fg, bg, alpha, char)
  if not self:inRange(x, y) then
    return false
  end
  x, y = self:absCoords(x, y)
  self.buffer:set(x, y, fg, bg, alpha, char)
end

function BufferView:get(x, y)
  if not self:inRange(x, y) then
    return false
  end
  x, y = self:absCoords(x, y)
  return self.buffer:get(x, y)
end

function BufferView.__getters:depth()
  return self.buffer.depth
end

function BufferView.__getters:palette()
  return self.buffer.palette
end

--------------------------------------------------------------------------------

local DiffBuffer = class(nil, {name = "wonderful.buffer.DiffBuffer"})

function DiffBuffer:__new__(base, head)
  if base.w ~= head.w or base.h ~= head.h then
    error("Base and head have different geometry")
  end
  self.base = base
  self.head = head
  self.w = base.w
  self.h = base.h
  self.cells = {}
end

function DiffBuffer:index(x, y)
  return self.w * (y - 1) + (x - 1) + 1
end

function DiffBuffer:inRange(x, y)
  return x >= 1 and x <= self.w and y >= 1 and y <= self.h
end

function DiffBuffer:rectInRange(x, y, w, h)
  return x >= 1 and x <= self.w and
         y >= 1 and y <= self.y and
         w >= 1 and x + w - 1 <= self.w and
         h >= 1 and y + h - 1 <= self.h
end

function DiffBuffer:coords(index)
  local i = index - 1
  local y = floor(i / self.w) + 1
  local x = floor(i) % self.w + 1
  return x, y
end

function DiffBuffer:set(x, y, diff)
  if not self:inRange(x, y) then
    return false
  end

  local i = self:index(x, y)

  self.cells[i] = diff
end

function DiffBuffer:get(x, y)
  if not self:inRange(x, y) then
    return false
  end

  local i = self:index(x, y)

  return self.cells[i]
end

function DiffBuffer:update()
  self:clear()

  for x = 1, self.w, 1 do
    for y = 1, self.h, 1 do
      self:set(x, y, self:cellsDiffer(x, y))
    end
  end
end

function DiffBuffer:fill(x0, y0, w, h, diff)
  for x = x0, x0 + w - 1, 1 do
    for y = y0, y0 + h - 1, 1 do
      self:set(x, y, diff)
    end
  end
end

function DiffBuffer:clear()
  self.cells = {}
end

function DiffBuffer:cellsDiffer(x, y)
  local chb, fgb, bgb = self.base:get(x, y)
  local chh, fgh, bgh = self.head:get(x, y)

  if bgb == bgh and fgb == fgh and chb == chh then
    return CellDiff.None
  elseif bgb == bgh and chb == chh and chb == " " then
    return CellDiff.None
  elseif bgb == bgh and fgb == fgh and chb ~= chh then
    return CellDiff.Char
  elseif bgb ~= bgh or fgb ~= fgh then
    return CellDiff.Color
  end
end

function DiffBuffer:getLine(x0, y0, vertical)
  local chars, fg0, bg0 = self.head:get(x0, y0)
  local x1, y1 = x0, y0

  for i = 1, not vertical and self.w or self.h, 1 do
    local x, y = x0 + i, y0
    if vertical then
      x, y = x0, y0 + i
    end
    if self:get(x, y) == CellDiff.None then
      return x1, y1, chars, fg0, bg0
    end
    local ch, fg, bg = self.head:get(x, y)
    if bg == bg0 and (fg == fg0 or ch == " ") then
      chars = chars .. ch
      x1, y1 = x, y
    else
      return x1, y1, chars, fg0, bg0
    end
  end

  return x1, y1, chars, fg0, bg0
end

function DiffBuffer:getRect(x0, y0, vertical)
  local x1, y1 = x0, x0
  local char, fg, bg = self.head:get(x0, y0)

  for i = 1, math.min(self.w, self.h), 1 do
    if self:areEqual(char, fg, bg,
                     x0 + i, y0,
                     x0 + i, y0 + i) and
        self:areEqual(char, fg, bg,
                      x0, y0 + i,
                      x0 + i - 1, y0 + i) then
      x1, y1 = x0 + i, y0 + i
    else
      break
    end
  end

  local dx, dy = 1, 0
  if vertical then
    dx, dy = 0, 1
  end

  for i = 1, not vertical and self.w or self.h, 1 do
    local x, y = x1 + i, y1
    if vertical then
      x, y = x1, y1 + i
    end
    if vertical and self:areEqual(char, fg, bg,
                                  x1 + 1, y0,
                                  x1 + 1, y1) or
        not vertical and self:areEqual(char, fg, bg,
                                       x0, y1 + 1,
                                       x1, y1 + 1) then
      x1, y1 = x, y
    else
      return x1, y1, char, fg, bg
    end
  end
  return x1, y1, char, fg, bg
end

function DiffBuffer:areEqual(ch, fg, bg, x0, y0, x1, y1)
  for x = x0, x1, 1 do
    for y = y0, y1, 1 do
      if self:get(x, y) == CellDiff.None then
        return false
      end
      local cch, cfg, cbg = self.head:get(x, y)
      if cbg ~= bg or cch ~= ch or cfg ~= fg and cch ~= " " then
        return false
      end
    end
  end
  return true
end

return {
  CellDiff = CellDiff,
  Buffer = Buffer,
  DiffBuffer = DiffBuffer,
}

