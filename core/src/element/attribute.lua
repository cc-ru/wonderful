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
-- @cl Attribute
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

--- Attributes that request composition when modified.
-- @cl AutocomposingAttribute
-- @extends Attribute
local AutocomposingAttribute = class(
  Attribute,
  {name = "wonderful.element.attribute.AutocomposingAttribute"}
)

--- @type AutocomposingAttribute

function AutocomposingAttribute:requestComposition()
  self:getElement():requestComposition()
end

--- @section end

--- The focus attribute.
-- @cl Focusable
-- @extends Attribute
local Focusable = class(Attribute,
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

--- The scroll box attribute.
-- @cl ScrollBox
-- @extends AutocomposingAttribute
-- @extends wonderful.geometry.Box
local ScrollBox = class(
  {AutocomposingAttribute, geometry.Box},
  {name = "wonderful.element.attribute.ScrollBox"}
)

--- @type ScrollBox

function ScrollBox:_initialize(x, y, w, h)
  self:set(x, y, w, h)
end

function ScrollBox:setX(x)
  self:superCall(geometry.Box, "setX", x)
  self:requestComposition()
end

function ScrollBox:setY(y)
  self:superCall(geometry.Box, "setY", y)
  self:requestComposition()
end

function ScrollBox:setWidth(w)
  self:superCall(geometry.Box, "setWidth", w)
  self:requestComposition()
end

function ScrollBox:setHeight(h)
  self:superCall(geometry.Box, "setHeight", h)
  self:requestComposition()
end

--- @section end

--- @export
return {
  Attribute = Attribute,
  AutocomposingAttribute = AutocomposingAttribute,
  Focusable = Focusable,
  ScrollBox = ScrollBox,
}

