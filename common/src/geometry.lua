--- Geometry objects (eg boxes).
-- @module wonderful.geometry

local class = require("lua-objects")

--- A box class, defined by its top-left corner coordinates, width, and height.
local Box = class(nil, {name = "wonderful.geometry.Box"})

--- A box class, defined by its top-left point coordinates, width, and height.
-- @type Box

--- The abscissa of the top-left point.
-- @field Box.x

--- The ordinate of the top-left point.
-- @field Box.y

--- The width of the box.
-- @field Box.w

--- The height of the box.
-- @field Box.h

--- True if both the position and dimensions are set.
-- @field Box.isStrict

--- True if the both dimensions are set.
-- @field Box.isDimStrict

--- True if both the ascissa and ordinate of the top-left point are set.
-- @field Box.isPosStrict

--- The abscissa of the bottom-right point.
-- @field Box.x1

--- The ordinate of the bottom-right point.
-- @field Box.y1

--- Construct a new box.
-- @tparam number x the abscissa of a top-left point
-- @tparam number y the ordinate of a top-left point
-- @tparam number w a width
-- @tparam nubmer h a height
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

--- Create a new box relative to itself.
-- @tparam number x the relative abscissa of a top-left point
-- @tparam number y the relative ordinate of a top-left point
-- @tparam number w a width
-- @tparam number h a height
-- @treturn wonderful.geometry.Box the box instance
function Box:relative(x, y, w, h)
  return Box(self.x + x - 1,
             self.y + y - 1,
             w,
             h)
end

--- Check if a point belongs to the box.
-- @tparam number x the abscissa of a point
-- @tparam number y the ordinate of a point
-- @treturn boolean
function Box:has(x, y)
  return x >= self.x and y >= self.y and
         x < self.x + self.w and y < self.y + self.h
end

--- Check if the box intersects with another one.
-- @tparam wonderful.geometry.Box other
-- @treturn boolean
function Box:intersects(other)
  return not (other.x > self.x1 or
              other.x1 < self.x or
              other.y > self.y1 or
              other.y1 < self.y)
end

--- Check if the box intersects with any of given.
-- @tparam {wonderful.geometry.Box,...} others a table of boxes
-- @treturn boolean
function Box:intersectsOneOf(others)
  for _, other in ipairs(others) do
    if self:intersects(other) then
      return true
    end
  end

  return false
end

--- Get an intersection of two boxes.
-- @tparam wonderful.geometry.Box other
-- @treturn wonderful.geometry.Box the intersection box
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

--- Unpack the box.
-- @treturn number x
-- @treturn number y
-- @treturn number w
-- @treturn number h
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

---
-- @section end

--- The margin class.
local Margin = class(nil, {name = "wonderful.geometry.Margin"})

--- The margin class.
-- @type Margin

--- The left margin.
-- @field Margin.l

--- The top margin.
-- @field Margin.t

--- The right margin.
-- @field Margin.r

--- The bottom margin.
-- @field Margin.b

--- Construct a new @{wonderful.geometry.Margin} class.
-- @tparam number l a left margin
-- @tparam number t a top margin
-- @tparam number r a right margin
-- @tparam number b a bottom margin
function Margin:__new__(l, t, r, b)
  self.l = type(l) == "number" and l or 0
  self.t = type(t) == "number" and t or 0
  self.r = type(r) == "number" and r or 0
  self.b = type(b) == "number" and b or 0
end

---
-- @section end

--- The padding class.
local Padding = class(nil, {name = "wonderful.geometry.Padding"})

--- The padding class.
-- @type Padding

--- The left padding.
-- @field Padding.l

--- The top padding.
-- @field Padding.t

--- The right padding.
-- @field Padding.r

--- The bottom padding.
-- @field Padding.b

--- Construct a new @{wonderful.geometry.Padding} instance.
-- @tparam number l a left padding
-- @tparam number t a top padding
-- @tparam number r a right padding
-- @tparam number b a bottom padding
function Padding:__new__(l, t, r, b)
  self.l = type(l) == "number" and l or 0
  self.t = type(t) == "number" and t or 0
  self.r = type(r) == "number" and r or 0
  self.b = type(b) == "number" and b or 0
end

---
-- @export
return {
  Box = Box,
  Margin = Margin,
  Padding = Padding,
}

