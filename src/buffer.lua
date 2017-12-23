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
         y >= 1 and y <= self.y and
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
  return self.cells[i + 2], self.cells[i], self.cells[i + 1]
end

function Buffer:fill(x0, y0, w, h, fg, bg, alpha, char)
  if fg == self.defaultFg then
    fg = nil
  end
  if bg == self.defaultBg then
    bg = nil
  end
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

return {
  Buffer = Buffer
}
