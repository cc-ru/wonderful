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

local Margin = require("wonderful.geometry").Margin

--- The abstract layout class.
local Layout = class(nil, {name = "wonderful.layout.Layout"})

--- The abstract layout class.
-- @type Layout

--- An abstract method to recompose the layout children.
-- Given a layout container, the method implementation should calculated and set
-- its children's calculated boxes.
-- @param el an instance of a class that inherits from `LayoutContainer`
function Layout:recompose(el)
  error("unimplemented abstract method Layout:recompose")
end

--- An abstract method to estimate the size of an element.
-- It should calculate the size that a layout container will take with all of
-- its children.
-- @param el an instance of a class that inherits from `LayoutContainer`
-- @treturn number the width
-- @treturn number the height
function Layout:sizeHint(el)
  error("unimplemented abstract method Layout:sizeHint")
end

---
-- @section end

--- The abstract layout item class.
local LayoutItem = class(nil, {name = "wonderful.layout.LayoutItem"})

--- The abstract layout item class.
-- @type LayoutItem

--- An abstract method to estimate the size of the element.
-- @treturn number the width
-- @treturn number the height
function LayoutItem:sizeHint()
  return 0, 0
end

--- An abstract method to get an instance of @{wonderful.geometry.Margin}.
-- @treturn wonderful.geometry.Margin the margin
function LayoutItem:getMargin()
  return Margin(0, 0, 0, 0)
end

--- An abstract method to get a stretch value of the element.
-- @treturn number the stretch value
function LayoutItem:getStretch()
  return 0
end

--- An abstract method that sets the element's calculated box.
-- @tparam wonderful.geometry.Box box the new calculated box
function LayoutItem:boxCalculated(box)
  error("unimplemented abstract method LayoutItem:boxCalculated")
end

---
-- @section end

--- The abstract layout container class.
local LayoutContainer = class(nil, {name = "wonderful.layout.LayoutContainer"})

--- The abstract layout container class.
-- @type LayoutContainer

--- An abstract method to get the layout items.
-- @treturn function an iterator function over the layout items
function LayoutContainer:getLayoutItems()
  error("unimplemented abstract method LayoutContainer:getLayoutItems")
end

--- An abstract method to get the layout padding.
-- @treturn wonderful.geometry.Padding the padding
function LayoutContainer:getLayoutPadding()
  error("unimplemented abstract method LayoutContainer:getLayoutPadding")
end

---
-- @export
return {
  Layout = Layout,
  LayoutItem = LayoutItem,
  LayoutContainer = LayoutContainer,
}

