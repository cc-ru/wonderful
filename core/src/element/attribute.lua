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

--- Default element attributes.
-- @module wonderful.element.attribute

local class = require("lua-objects")

local geometry = require("wonderful.geometry")
local tableUtil = require("wonderful.util.table")

local isin = tableUtil.isin

--- The base attribute class.
local Attribute = class(
  nil,
  {name = "wonderful.element.attribute.Attribute"}
)

--- @type Attribute

--- Construct a new attribute.
-- @param element the element to which the attribute is applied to
-- @param ... the arguments to the concrete attribute initializer
function Attribute:__new__(element, ...)
  self.__element = element

  self:_initialize(...)
end

--- Initialize the attribute with the default or passed value(s).
--
-- This method is called automatically by the attribute constructor.
function Attribute:_initialize() end

--- Get the element to which the attribute is applied to.
-- @return the element
function Attribute:getElement()
  return self.__element
end

--- @section end

--- Attributes that mark its element's parent for recomposing.
local RecomposingAttribute = class(
  Attribute,
  {name = "wonderful.element.attribute.RecomposingAttribute"}
)

--- @type RecomposingAttribute

function RecomposingAttribute:recomposeParent()
  local parent = self:getElement():getParent()

  if parent then
    parent:markToRecompose()
  end
end

--- @section end

--- The position attribute.
local Position = class(
  RecomposingAttribute,
  {name = "wonderful.element.attribute.Position"}
)

--- The position attribute.
-- @type Position

--- The default value (`"static"`).
Position.DEFAULT = "static"

--- The possible options (`"static"`, `"absolute"`, `"relative"`, `"fixed"`).
Position.OPTIONS = {
  static = true,
  absolute = true,
  relative = true,
  fixed = true
}

function Position:_initialize(value)
  self:set(value)
end

--- Checks if the value is set to `"static"` or `"relative"`.
-- @treturn boolean
function Position:isFlowElement()
  return self._value == "static" or self._value == "relative"
end

--- Set a new attribute value.
-- @tparam ?string value one of "static", "absolute", "relative", or "fixed"
function Position:set(value)
  self._value = self.OPTIONS[value] and value or self.DEFAULT
  self:recomposeParent()
end

function Position:get()
  return self._value
end

--- @section end

--- The bounding box attribute.
local BoundingBox = class(
  Attribute,
  {name = "wonderful.element.attribute.BoundingBox"}
)

--- @type BoundingBox

function BoundingBox:_initialize(l, t, w, h)
  self:set(l, t, w, h)
end

--- Set a new bounding box.
-- @tparam ?int l the left offset
-- @tparam ?int t the top offset
-- @tparam ?int w the width
-- @tparam ?int h the height
function BoundingBox:set(l, t, w, h)
  self:setLeft(l)
  self:setTop(t)
  self:setWidth(w)
  self:setHeight(h)
end

--- Set the left offset.
-- @tparam ?int l the left offset
function BoundingBox:setLeft(l)
  self._left = tonumber(l)
  self:recomposeParent()
end

--- Set the top offset.
-- @tparam ?int t the top offset
function BoundingBox:setTop(t)
  self._top = tonumber(t)
  self:recomposeParent()
end

--- Set the width.
-- @tparam ?int w the width
function BoundingBox:setWidth(w)
  self._width = tonumber(w)
  self:recomposeParent()
end

--- Set the height.
-- @tparam ?int h the height
function BoundingBox:setHeight(h)
  self._height = tonumber(h)
  self:recomposeParent()
end

--- Get the left offset.
-- @treturn ?int the offset
function BoundingBox:getLeft()
  return self._left
end

--- Get the top offset.
-- @treturn ?int the offset
function BoundingBox:getTop()
  return self._top
end

--- Get the width.
-- @treturn ?int the width
function BoundingBox:getWidth()
  return self._width
end

--- Get the height.
-- @treturn ?int the height
function BoundingBox:getHeight()
  return self._height
end

--- @section end

--- The margin attribute.
-- @see wonderful.geometry.Margin
local Margin = class(
  {RecomposingAttribute, geometry.Margin},
  {name = "wonderful.element.attribute.Margin"}
)

--- @type Margin

function Margin:_initialize(l, t, r, b)
  self:set(l, t, r, b)
end

function Margin:setLeft(l)
  self:superCall(geometry.Margin, "setLeft", l)
  self:recomposeParent()
end

function Margin:setTop(t)
  self:superCall(geometry.Margin, "setTop", t)
  self:recomposeParent()
end

function Margin:setRight(r)
  self:superCall(geometry.Margin, "setRight", r)
  self:recomposeParent()
end

function Margin:setBottom(b)
  self:superCall(geometry.Margin, "setBottom", b)
  self:recomposeParent()
end

--- @section end

--- The padding attribute.
-- @see wonderful.geometry.Padding
local Padding = class(
  {RecomposingAttribute, geometry.Padding},
  {name = "wonderful.element.attribute.Padding"}
)

--- @type Padding

function Padding:_initialize(l, t, r, b)
  self:set(l, t, r, b)
end

function Padding:setLeft(l)
  self:superCall(geometry.Padding, "setLeft", l)
  self:recomposeParent()
end

function Padding:setTop(t)
  self:superCall(geometry.Padding, "setTop", t)
  self:recomposeParent()
end

function Padding:setRight(r)
  self:superCall(geometry.Padding, "setRight", r)
  self:recomposeParent()
end

function Padding:setBottom(b)
  self:superCall(geometry.Padding, "setBottom", b)
  self:recomposeParent()
end

--- @section end

--- The focus attribute.
local Focusable = class(RecomposingAttribute,
                        {name = "wonderful.element.attribute.Focusable"})

--- @type Focusable

function Focusable:_initialize(enable)
  self:setEnabled(enable)
end

--- Enable or disable focusing for the element.
-- @tparam[opt=true] boolean enable whether to enable focusing on an element
function Focusable:setEnabled(enable)
  if enable == nil then
    self._enabled = true
  else
    self._enabled = not not enable
  end
end

--- Check whether focusing is enabled for the element.
-- @treturn boolean whether focusing is enabled
function Focusable:isEnabled()
  return self._enabled
end

--- @section end

--- The stretch attribute.
-- @see wonderful.layout.Layout
local Stretch = class(Attribute, {name = "wonderful.element.attribute.Stretch"})

--- @type Stretch

--- The default value of the attribute (`0`).
Stretch.DEFAULT = 0

function Stretch:_initialize(stretch)
  self:set(stretch)
end

--- Set the stretch value.
-- @tparam ?number stretch the value
function Stretch:set(stretch)
  if type(stretch) == "number" and stretch >= 0 then
    self._value = stretch
  else
    self._value = self.DEFAULT
  end

  self:recomposeParent()
end

--- Get the stretch value.
-- @treturn number the stretch value
function Stretch:get()
  return self._value
end

--- @section end

--- The scroll box attribute.
-- @see wonderful.geometry.Box
local ScrollBox = class(
  {RecomposingAttribute, geometry.Box},
  {name = "wonderful.element.attribute.ScrollBox"}
)

--- @type ScrollBox

function ScrollBox:_initialize(x, y, w, h)
  self:set(x, y, w, h)
end

function ScrollBox:setX(x)
  self:superCall(geometry.Box, "setX", x)
  self:recomposeParent()
end

function ScrollBox:setY(y)
  self:superCall(geometry.Box, "setY", y)
  self:recomposeParent()
end

function ScrollBox:setWidth(w)
  self:superCall(geometry.Box, "setWidth", w)
  self:recomposeParent()
end

function ScrollBox:setHeight(h)
  self:superCall(geometry.Box, "setHeight", h)
  self:recomposeParent()
end

--- @section end

--- @export
return {
  Attribute = Attribute,
  RecomposingAttribute = RecomposingAttribute,
  Position = Position,
  BoundingBox = BoundingBox,
  Margin = Margin,
  Padding = Padding,
  Focusable = Focusable,
  Stretch = Stretch,
  ScrollBox = ScrollBox,
}

