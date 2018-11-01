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

--- The @{wonderful.widget.Widget|Widget} class.
-- @module wonderful.widget

local class = require("lua-objects")

local attribute = require("wonderful.element.attribute")

local RelativeLayout = require("wonderful.layout.relative").RelativeLayout

--- The base widget class.
--
-- A widget is an element that can be rendered. It also acts as a relative
-- layout, allowing to add children at fixed relative position.
--
-- @cl wonderful.widget.Widget
-- @extends wonderful.layout.relative.RelativeLayout
local Widget = class(RelativeLayout, {name = "wonderful.widget.Widget"})

--- @type Widget

--- @field Widget.focusable
-- The @{wonderful.element.attribute.Focusable|focus} attribute. Controls
-- whether the widget can receive focus.

--- Construct a new widget instance.
function Widget:__new__(args)
  args = args or {}

  RelativeLayout.__new__(self, args)

  self.focusable = attribute.Focusable(self, false)

  -- The flag is defined in `Element`; widgets have to be rendered at least
  -- once, so the flag is raised here.
  self._shouldRender:raise()
end

--- An abstract method to render the widget.
--
-- If you're making your own widget, provide an implementation for this method.
--
-- Calling this method forcefully redraws the widget, which is discouraged.
-- Consider using `requestRender` instead.
--
-- @tparam wonderful.buffer.BufferView fbView a view on the framebuffer
-- @see Widget:requestRender
function Widget:_render(fbView)
  error("Abstract method Widget:_render unimplemented")
end

--- Flag the element to render it the next time `Wonderful:render` is called.
function Widget:requestRender(_quiet)
  self._shouldRender:raise(_quiet)
end

--- Check whether render is requested, and call `_render` if it is. Do
-- nothing otherwise.
--
-- @tparam wonderful.buffer.BufferView fbView a view on the framebuffer
-- @treturn boolean whether the element was actually rendered
-- @see Widget:requestRender
function Widget:flush(fbView)
  if self._shouldRender:isRaised() then
    self:_render(fbView)
    self._shouldRender:lower()

    return true
  end

  return false
end

--- Check whether the element is focused.
-- @treturn boolean
function Widget:isFocused(_element)
  if self:hasParent() then
    -- Some duck typing: the `Document` class also implements the method
    -- `isFocused`, and, if the tree is rooted, that implementation performs the
    -- actual check.
    return self:getParent():isFocused(_element or self)
  else
    return false
  end
end

function Widget:requestComposition()
  RelativeLayout.requestComposition(self)
  self:requestRender()
end

--- @export
return {
  Widget = Widget
}
