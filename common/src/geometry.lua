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

--- Geometry objects (eg boxes).
-- @module wonderful.geometry

local class = require("lua-objects")

--- A box class, defined by its top-left corner coordinates, width, and height.
local Box = class(nil, {name = "wonderful.geometry.Box"})

--- A box class, defined by its top-left point coordinates, width, and height.
-- @type Box

--- Construct a new box.
-- @tparam number x the abscissa of a top-left point
-- @tparam number y the ordinate of a top-left point
-- @tparam number w a width
-- @tparam nubmer h a height
function Box:__new__(x, y, w, h)
  self._x = x
  self._y = y
  self._w = w
  self._h = h
end

function Box:getX()
  return self._x
end

function Box:getY()
  return self._y
end

function Box:getWidth()
  return self._w
end

function Box:getHeight()
  return self._h
end

function Box:setX(x)
  self._x = x
end

function Box:setY(y)
  self._y = y
end

function Box:setWidth(w)
  self._w = w
end

function Box:setHeight(h)
  self._h = h
end

function Box:__tostring__()
  return ("%s { x = %d, y = %d, w = %d, h = %d }"):format(
    self.NAME,
    self._x or -1, self._y or -1,
    self._w or -1, self._h or -1
  )
end

--- Create a new box relative to itself.
-- @tparam number x the relative abscissa of a top-left point
-- @tparam number y the relative ordinate of a top-left point
-- @tparam number w a width
-- @tparam number h a height
-- @treturn wonderful.geometry.Box the box instance
function Box:relative(x, y, w, h)
  return Box(self._x + x - 1,
             self._y + y - 1,
             w,
             h)
end

--- Check if a point belongs to the box.
-- @tparam number x the abscissa of a point
-- @tparam number y the ordinate of a point
-- @treturn boolean
function Box:has(x, y)
  return x >= self._x and y >= self._y and
         x < self._x + self._w and y < self._y + self._h
end

--- Check if the box intersects with another one.
-- @tparam wonderful.geometry.Box other
-- @treturn boolean
function Box:intersects(other)
  return not (other:getX() > self:getX1() or
              other:getX1() < self:getX() or
              other:getY() > self:getY1() or
              other:getY1() < self:getY())
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
  assert(self:isStrict() and other:isStrict(), "both boxes must be strict")

  if self:getWidth() <= 0 or self:getHeight() <= 0 or other:getWidth() <= 0 or other:getHeight() <= 0 then
    return Box(self:getX(), self:getY(), 0, 0)
  end

  if not self:intersects(other) then
    return Box(other:getX(), other:getY(), 0, 0)
  end

  local x = math.max(self:getX(), other:getX())
  local y = math.max(self:getY(), other:getY())
  local x1 = math.min(self:getX1(), other:getX1())
  local y1 = math.min(self:getY1(), other:getY1())
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
  return self:getX(), self:getY(), self:getWidth(), self:getHeight()
end

function Box:isStrict()
  return self:getX() and self:getY() and self:getWidth() and self:getHeight()
end

function Box:isDimStrict()
  return self:getWidth() and self:getHeight()
end

function Box:isPosStrict()
  return self:getWidth() and self:getHeight()
end

function Box:getX1()
  return self:getX() + self:getWidth() - 1
end

function Box:getY1()
  return self:getY() + self:getHeight() - 1
end

---
-- @section end

--- The margin class.
local Margin = class(nil, {name = "wonderful.geometry.Margin"})

--- The margin class.
-- @type Margin

--- Construct a new @{wonderful.geometry.Margin} class.
-- @tparam number l a left margin
-- @tparam number t a top margin
-- @tparam number r a right margin
-- @tparam number b a bottom margin
function Margin:__new__(l, t, r, b)
  self._l = type(l) == "number" and l or 0
  self._t = type(t) == "number" and t or 0
  self._r = type(r) == "number" and r or 0
  self._b = type(b) == "number" and b or 0
end

function Margin:getLeft()
  return self._l
end

function Margin:getTop()
  return self._t
end

function Margin:getRight()
  return self._r
end

function Margin:getBottom()
  return self._b
end

--- @section end

--- The padding class.
local Padding = class(nil, {name = "wonderful.geometry.Padding"})

--- The padding class.
-- @type Padding

--- Construct a new @{wonderful.geometry.Padding} instance.
-- @tparam number l a left padding
-- @tparam number t a top padding
-- @tparam number r a right padding
-- @tparam number b a bottom padding
function Padding:__new__(l, t, r, b)
  self._l = type(l) == "number" and l or 0
  self._t = type(t) == "number" and t or 0
  self._r = type(r) == "number" and r or 0
  self._b = type(b) == "number" and b or 0
end

function Padding:getLeft()
  return self._l
end

function Padding:getTop()
  return self._t
end

function Padding:getRight()
  return self._r
end

function Padding:getBottom()
  return self._b
end

--- @export
return {
  Box = Box,
  Margin = Margin,
  Padding = Padding,
}

