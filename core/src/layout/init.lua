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

--- The abstract layout classes.
-- @module wonderful.layout

local class = require("lua-objects")

local attribute = require("wonderful.element.attribute")
local geometry = require("wonderful.geometry")

local Element = require("wonderful.element").Element
local TrappedFlag = require("wonderful.util.flag").TrappedFlag

local function shouldComposeGetter(layout)
  local parent = layout:getParent()

  if parent then
    return parent._shouldCompose
  end
end

--- The base layout class.
--
-- Handles element positioning.
--
-- @cl wonderful.layout.Layout
-- @extends wonderful.element.Element
local Layout = class(Element, {name = "wonderful.layout.Layout"})

--- @type Layout

--- @field Layout.scrollBox
-- The @{wonderful.element.attribute.ScrollBox|ScrollBox} attribute.

--- Construct a new instance.
-- @tparam table args keyword argument table
function Layout:__new__(args)
  args = args or {}

  Element.__new__(self, args)

  self._shouldCompose = TrappedFlag(shouldComposeGetter, true, true, self)
  self._boundingBox = geometry.Box()

  self.scrollBox = attribute.ScrollBox(self, table.unpack(args.scrollBox or {}))
end

--- Abstract method to compose children.
--
-- if you're making your own layout, provide an implementation for this method.
--
-- Calling this method forcefully composes the children, which is discouraged.
-- Consider using `requestComposition` instead.
--
-- @tparam wonderful.geometry.Box layoutBox the layout box relative to which
-- elements are to be composed
-- @see Layout:requestComposition
function Layout:_compose(layoutBox)
  error("Abstract method Layout:_compose unimplemented")
end

--- Flag the element to compose its children the next time `Wonderful:compose`
-- is called.
function Layout:requestComposition()
  self._shouldCompose:raise()
end

--- Checks whether composition is requested, and calls `_compose` if it is. Does
-- nothing otherwise.
--
-- @treturn boolean whether composition was requested
-- @see Layout:requestComposition
function Layout:commitComposition()
  if self:isFreeTree() then
    return false
  end

  if self._shouldCompose:isRaised() then
    self:_compose(self:getLayoutBox())
    self._shouldCompose:lower()

    return true
  end

  return false
end

--- Abstract method to estimate the layout size, including its children.
-- @treturn int the width
-- @treturn int the height
function Layout:sizeHint()
  error("Abstract method Layout:sizeHint unimplemented")
end

--- Get the element's bounding box.
-- @treturn wonderful.geometry.Box
function Layout:getBoundingBox()
  return self._boundingBox
end

--- Calculate the layout's viewport.
--
-- Viewport is the actual visible area of an element.
--
-- @treturn wonderful.geometry.Box
function Layout:getViewport()
  local parent = self:getParent()

  if parent then
    -- Crop the element so that it does not exceed the parent's viewport.
    return parent:getViewport():intersection(self:getBoundingBox())
  else
    -- The root element is never scrolled, so it may never be cropped;
    -- therefore, its viewport is its bounding box.
    return self:getBoundingBox()
  end
end

--- Calculate the layout box relative to which the layout's children are
-- positioned.
--
-- The layout box is the bounding box shifted by the values of the scroll box.
--
-- @treturn wonderful.geometry.Box
function Layout:getLayoutBox()
  return self:getBoundingBox():relative(self.scrollBox:unpack())
end

--- @export
return {
  Layout = Layout,
}

