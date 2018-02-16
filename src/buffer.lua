local class = require("lua-objects")

local util = require("wonderful.util")

local floor = math.floor

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
  return 3 * self.w * (y - 1) + 3 * (x - 1) + 3
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

function Buffer:_set(x, y, fg, bg, alpha, char)
  local i = self:index(x, y)

  local cbg = self.cells[i + 1] or self.defaultBg

  fg = self:approximate(self:alphaBlend(cbg, fg, alpha))
  bg = self:approximate(self:alphaBlend(cbg, bg, alpha))

  if bg == self.defaultBg then
    bg = nil
  end

  if fg == self.defaultFg then
    fg = nil
  end

  if char == " " then
    char = nil
  end

  self.cells[i] = fg
  self.cells[i + 1] = bg
  self.cells[i + 2] = char
end

function Buffer:set(x, y, fg, bg, alpha, char)
  checkArg(1, x, "number")
  checkArg(2, y, "number")
  checkArg(3, fg, "number")
  checkArg(4, bg, "number")
  checkArg(5, alpha, "number")
  checkArg(6, char, "string")

  if not self:inRange(x, y) then
    return false
  end

  return self:_set(x, y, fg, bg, alpha, char)
end

function Buffer:_get(x, y)
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

function Buffer:get(x, y)
  checkArg(1, x, "number")
  checkArg(2, y, "number")

  if not self:inRange(x, y) then
    return false
  end

  return self:_get(x, y)
end

function Buffer:fill(x0, y0, w, h, fg, bg, alpha, char)
  if w <= 0 or h <= 0 then
    return
  end

  local x1 = x0 + w - 1
  local y1 = x0 + h - 1

  if x1 <= 0 or y1 <= 0 then
    return
  end

  x0 = math.max(x0, 1)
  y0 = math.max(y0, 1)
  x1 = math.min(x1, self.w)
  y1 = math.min(y1, self.h)

  for x = x0, x1, 1 do
    for y = y0, y1, 1 do
      self:_set(x, y, fg, bg, alpha, char)
    end
  end
end

function Buffer:view(x, y, w, h)
  if not self:rectInRange(x, y, w, h) then
    return false
  end
  local view = BufferView(self, x, y, w, h)
  view:optimize()
  return view
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

function BufferView:_set(x, y, fg, bg, alpha, char)
  x, y = self:absCoords(x, y)
  self.buffer:set(x, y, fg, bg, alpha, char)
end

function BufferView:_get(x, y)
  x, y = self:absCoords(x, y)
  return self.buffer:get(x, y)
end

function BufferView.__getters:depth()
  return self.buffer.depth
end

function BufferView.__getters:palette()
  return self.buffer.palette
end

return {
  Buffer = Buffer,
  BufferView = BufferView,
}

