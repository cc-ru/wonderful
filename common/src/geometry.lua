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
-- @cl Box
local Box = class(nil, {name = "wonderful.geometry.Box"})

--- @type Box

--- Construct a new box.
-- @tparam ?number x the left coordinate
-- @tparam ?number y the top coordinate
-- @tparam ?number w a width
-- @tparam ?nubmer h a height
function Box:__new__(x, y, w, h)
  self:set(x, y, w, h)
end

--- Get the left coordinate.
-- @treturn ?number the left coordinate
function Box:getX()
  return self._x
end

--- Get the top coordinate.
-- @treturn ?number the top coordinate
function Box:getY()
  return self._y
end

--- Get the width.
-- @treturn ?number the width
function Box:getWidth()
  return self._w
end

--- Get the height.
-- @treturn ?number the height
function Box:getHeight()
  return self._h
end

--- Set new box values. Shorthand for setting each value individually.
function Box:set(x, y, w, h)
  self:setX(x)
  self:setY(y)
  self:setWidth(w)
  self:setHeight(h)
end

--- Copy the values from another box.
-- @tparam Box box the box
function Box:setBox(box)
  self:set(box:unpack())
end

--- Set the left coordinate.
-- @tparam ?number x the left coordinate
function Box:setX(x)
  self._x = type(x) == "number" and x or nil
end

--- Set the top coordinate.
-- @tparam ?number y the top coordinate
function Box:setY(y)
  self._y = type(y) == "number" and y or nil
end

--- Set the width.
-- @tparam ?number w the width
function Box:setWidth(w)
  self._w = type(w) == "number" and w or nil
end

--- Set the height.
-- @tparam ?number h the height
function Box:setHeight(h)
  self._h = type(h) == "number" and h or nil
end

function Box:__tostring__()
  return ("%s { x = %d, y = %d, w = %d, h = %d }"):format(
    self.NAME,
    self._x or -1, self._y or -1,
    self._w or -1, self._h or -1
  )
end

--- Create a new box relative to itself.
--
-- If some arguments are `nil`, the values are copied from self.
--
-- @tparam ?number x the relative abscissa of the top-left point
-- @tparam ?number y the relative ordinate of the top-left point
-- @tparam ?number w a width
-- @tparam ?number h a height
-- @treturn wonderful.geometry.Box the box instance
function Box:relative(x, y, w, h)
  return Box(self._x + (x and x - 1),
             self._y + (y and y - 1),
             w or self._w,
             h or self._h)
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

--- Check if all parameters are defined.
-- @treturn boolean whether all paramter are defined
function Box:isStrict()
  return self:getX() and self:getY() and self:getWidth() and self:getHeight()
end

--- Check if the width and height are both defined.
-- @treturn boolean whether width and height are both defined
function Box:isDimStrict()
  return self:getWidth() and self:getHeight()
end

--- Check if the top-left point is defined.
-- @treturn boolean whether the top-left point is defined
function Box:isPosStrict()
  return self:getWidth() and self:getHeight()
end

--- Get the right coordinate.
-- @treturn number the right coordinate
function Box:getX1()
  return self:getX() + self:getWidth() - 1
end

--- Get the bottom coordinate.
-- @treturn number the bottom coordinate
function Box:getY1()
  return self:getY() + self:getHeight() - 1
end

--- @section end

--- @export
return {
  Box = Box,
}

