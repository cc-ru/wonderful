local class = require("lua-objects")

local Box = class(nil, {name = "wonderful.geometry.Box"})

function Box:__new__(x, y, w, h)
  self.x = x
  self.y = y
  self.w = w
  self.h = h
end

function Box:__tostring__()
  return ("%s { x = %d, y = %d, w = %d, h = %d }"):format(
    self.NAME,
    self.x or -1, self.y or -1,
    self.w or -1, self.h or -1
  )
end

-- Create a new box relative to self
function Box:relative(x, y, w, h)
  return Box(self.x + x - 1,
             self.y + y - 1,
             w,
             h)
end

function Box:has(x, y)
  return x >= self.x and y >= self.y and
         x < self.x + self.w and y < self.y + self.h
end

function Box:intersects(other)
  -- return (math.abs(self.x - other.x) * 2 < (self.w + other.w)) and
  --        (math.abs(self.y - other.y) * 2 < (self.h + other.h))

  return not (other.x > self.x1 or
              other.x1 < self.x or
              other.y > self.y1 or
              other.y1 < self.y)
end

function Box:intersectsOneOf(others)
  for _, other in ipairs(others) do
    if self:intersects(other) then
      return true
    end
  end

  return false
end

function Box:intersection(other)
  assert(self.isStrict and other.isStrict, "both boxes must be strict")

  if self.w <= 0 or self.h <= 0 or other.w <= 0 or other.h <= 0 then
    return Box(self.x, self.y, 0, 0)
  end

  if not self:intersects(other) then
    return Box(other.x, other.y, 0, 0)
  end

  local x = math.max(self.x, other.x)
  local y = math.max(self.y, other.y)
  local x1 = math.min(self.x1, other.x1)
  local y1 = math.min(self.y1, other.y1)
  local w = x1 - x + 1
  local h = y1 - y + 1

  return Box(x, y, w, h)
end

function Box:unpack()
  return self.x, self.y, self.w, self.h
end

function Box.__getters:isStrict()
  return self.x and self.y and self.w and self.h
end

function Box.__getters:isDimStrict()
  return self.w and self.h
end

function Box.__getters:isPosStrict()
  return self.w and self.h
end

function Box.__getters:x1()
  return self.x + self.w - 1
end

function Box.__getters:y1()
  return self.y + self.h - 1
end

local Margin = class(nil, {name = "wonderful.geometry.Margin"})

function Margin:__new__(l, t, r, b)
  self.l = type(l) == "number" and l or 0
  self.t = type(t) == "number" and t or 0
  self.r = type(r) == "number" and r or 0
  self.b = type(b) == "number" and b or 0
end

local Padding = class(nil, {name = "wonderful.geometry.Padding"})

function Padding:__new__(l, t, r, b)
  self.l = type(l) == "number" and l or 0
  self.t = type(t) == "number" and t or 0
  self.r = type(r) == "number" and r or 0
  self.b = type(b) == "number" and b or 0
end

return {
  Box = Box,
  Margin = Margin,
  Padding = Padding,
}

