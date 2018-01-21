local class = require("lua-objects")

local Box = class(nil, {name = "wonderful.geometry.Box"})

function Box:__new__(x, y, w, h)
  self.x = x
  self.y = y
  self.w = w
  self.h = h
end

function Box:__tostring__()
  return ("Box { x = %d, y = %d, w = %d, h = %d }"):format(
    self.x, self.y,
    self.w, self.h
  )
end

function Box:intersects(other)
  return (math.abs(self.x - other.x) * 2 < (self.w + other.w)) and
         (math.abs(self.y - other.y) * 2 < (self.h + other.h))
end

function Box:intersectsOneOf(others)
  for _, other in ipairs(others) do
    if self:intersects(other) then
      return true
    end
  end

  return false
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

local Margin = class(nil, {name = "wonderful.geometry.Margin"})

function Margin:__new__(l, t, r, b)
  self.l = l
  self.t = t
  self.r = r
  self.b = b
end

local Padding = class(nil, {name = "wonderful.geometry.Padding"})

function Padding:__new__(l, t, r, b)
  self.l = l
  self.t = t
  self.r = r
  self.b = b
end

return {
  Box = Box,
  Margin = Margin,
Padding = Padding
}

