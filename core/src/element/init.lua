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

--- The @{wonderful.element.Element|Element} class.
-- @module wonderful.element

local class = require("lua-objects")

local attribute = require("wonderful.element.attribute")
local event = require("wonderful.event")
local geometry = require("wonderful.geometry")
local layout = require("wonderful.layout")
local node = require("wonderful.element.node")

local VBoxLayout = require("wonderful.layout.box").VBoxLayout

--- The base element class.
local Element = class({node.Node, layout.LayoutContainer, layout.LayoutItem,
                       event.EventTarget},
                      {name = "wonderful.element.Element"})

--- @type Element

--- Construct a new element instance.
function Element:__new__(args)
  args = args or {}

  self:superCall(node.Node, "__new__")
  self:superCall(event.EventTarget, "__new__")

  self.position = attribute.Position(self, args.position)

  self.boundingBox = attribute.BoundingBox(self,
                                           table.unpack(args.boundingBox or {}))

  self.margin = attribute.Margin(self, table.unpack(args.margin or {}))
  self.padding = attribute.Padding(self, table.unpack(args.padding or {}))
  self.focusable = attribute.Focusable(self, args.focusable)
  self.stretch = attribute.Stretch(self, args.stretch)
  self.scrollBox = attribute.ScrollBox(self, table.unpack(args.scrollBox or {}))

  self._calculatedBox = geometry.Box()
  self._focused = false
  self._markedToRecompose = true
  self._hasMarkedDescendant = true

  self:setLayout(VBoxLayout())
  self:requestRender()
end

--- Abstract method to render the element.
--
-- If you're making your own element, provide an implementation for this method.
--
-- Calling this method on an element forcefully redraws it.
-- Consider using `requestRender` instead.
--
-- @tparam wonderful.buffer.BufferView fbView a view on the framebuffer
-- @see Element:requestRender
function Element:_render(fbView)
  error("Abstract method Element:_render not implemented")
end

--- Flag the element so that it's rendered the next time `Wonderful:render`
-- is called.
function Element:requestRender()
  self._shouldRedraw = true

  self:_notifyParentsOfRenderRequest()
end

--- Conditionally render the element.
--
-- This method does nothing if the element isn't flagged.
--
-- @tparam wonderful.buffer.BufferView fbView a view on the framebuffer
-- @treturn boolean whether the element was actually rendered
-- @see Element:requestRender
function Element:render(fbView)
  if self._shouldRedraw then
    self:_render(fbView)
    self._shouldRedraw = false

    return true
  end

  return false
end

function Element:getParentEventTarget()
  return self:getParent()
end

function Element:getChildEventTargets()
  return self:getChildren()
end

function Element:getLayoutItems()
  return coroutine.wrap(function()
    for _, element in ipairs(self:getChildren()) do
      if element:isFlowElement() then
        coroutine.yield(element)
      end
    end
  end)
end

function Element:getLayoutPadding()
  return self.padding
end

function Element:getLayoutBox()
  local x, y, w, h = self._calculatedBox:unpack()
  local scrollBox = self.scrollBox

  if scrollBox then
    if scrollBox:getX() then
      x = x + scrollBox:getX()
    end

    if scrollBox:getY() then
      y = y + scrollBox:getY()
    end

    if scrollBox:getWidth() then
      w = scrollBox:getWidth()
    end

    if scrollBox:getHeight() then
      h = scrollBox:getHeight()
    end
  end

  return geometry.Box(x, y, w, h)
end

--- Insert a child at a given index.
-- @tparam int index the index
-- @param child the child element
function Element:insertChild(index, child)
  self:superCall(node.Node, "insertChild", index, child)

  self:recompose(true)
end

--- Remove a child at a given index.
-- @tparam int index the index
-- @return `false` or the removed element
function Element:removeChild(index)
  local child = self:superCall(node.Node, "removeChild", index)

  if not child then
    return false
  end

  self:recompose(true)

  return child
end

function Element:sizeHint()
  local width, height = self._layout:sizeHint(self)
  local padding = self:getLayoutPadding()
  return width + padding:getLeft() + padding:getRight(),
         height + padding:getTop() + padding:getBottom()
end

--- Mark the element to be recomposed when `recompose` is called for it or
-- one of its ascendants.
--
-- @see wonderful.element.Element:recompose
function Element:markToRecompose()
  self._markedToRecompose = true
  self:_markParent()
end

--- Recompose the element: calculate boxes for its children.
--
-- **Does not** recompose self if not marked, unless forced.
--
-- @tparam[opt=false] boolean force whether to force recomposing
-- @see wonderful.element.Element:markToRecompose
function Element:recompose(force)
  if self:isFreeTree() then
    return
  end

  if force then
    self._markedToRecompose = true
  end

  if self._markedToRecompose then
    self._layout:recompose(self)
    self:requestRender()

    local bbox, x, y, w, h
    local layoutBox = self:getLayoutBox()
    local calcBox = self._calculatedBox

    for _, element in ipairs(self:getChildren()) do
      local position = element.position

      if not position:isFlowElement() then
        bbox = element.boundingBox

        if position:get() == "absolute" then
          x, y = layoutBox:getX(), layoutBox:getY()
        elseif position:get() == "fixed" then
          x, y = calcBox:getX(), calcBox:getY()
        end

        w, h = element:sizeHint()

        element:setCalculatedBox(geometry.Box(
          x + (bbox:getLeft() or 0),
          y + (bbox:getTop() or 0),
          bbox:getWidth() or w,
          bbox:getHeight() or h
        ))
      end
    end
  end

  if self._hasMarkedDescendant or self._markedToRecompose then
    for _, element in pairs(self:getChildren()) do
      if self._markedToRecompose then
        element._markedToRecompose = true
      end

      if element._markedToRecompose or element._hasMarkedDescendant then
        element:recompose()
      end
    end
  end

  self._hasMarkedDescendant = false
  self._markedToRecompose = false
end

--- Set a new calculated box.
-- @tparam wonderful.geometry.Box new the new box
function Element:setCalculatedBox(new)
  local position = self.position

  if position:get() == "relative" then
    local bbox = self.boundingBox
    new:setX(new:getX() + (bbox and bbox:getLeft() or 0))
    new:setY(new:getY() + (bbox and bbox:getTop() or 0))
  end

  self._calculatedBox = new
end

function Element:setLayout(layout)
  layout:optimize()
  self._layout = layout
end

function Element:getLayout(layout)
  return self._layout
end

--- Get the element's margin.
-- @treturn wonderful.element.attribute.Margin
function Element:getMargin()
  return self.margin
end

--- Get the element's stretch value.
-- @treturn wonderful.element.attribute.Stretch
function Element:getStretch()
  return self.stretch:get()
end

function Element:getDisplay()
  return self:getRoot()._globalDisplay
end

function Element:isFlowElement()
  return self.position:isFlowElement()
end

function Element:getViewport()
  return self:getParent():getViewport():intersection(self._calculatedBox)
end

function Element:isFreeTree()
  return not self:getRoot():isa(require("wonderful.element.document").Document)
end

function Element:getCalculatedBox()
  return self._calculatedBox
end

function Element:isFocused()
  return self._focused
end

--- Dumps the tree rooted at self into the stream.
--
-- Calls `func` for each element. Returned values are passed to
-- `string.format` and appended to the element line.
--
-- The stream will be automatically closed.
--
-- @tparam function(element) func the function to call
-- @tparam {write=function,close=function} stream the stream
function Element:dumpTree(func, stream)
  stream:write("Dump of tree rooted at " .. tostring(self) .. ":\n")

  self:nlrWalk(function(node)
    stream:write(("%s- %s: %s\n"):format(
      ("  "):rep(node:getLevel() - 1),
      tostring(node),
      string.format(func(node))
    ))
  end)

  stream:write("\n")
  stream:close()
end

function Element:_markParent()
  local ascendant = self:getParent()

  while ascendant do
    ascendant._hasMarkedDescendant = true

    ascendant = ascendant:getParent()
  end
end

function Element:_notifyParentsOfRenderRequest()
  local ascendant = self:getParent()

  while ascendant do
    ascendant._renderRequestedByChildren = true

    ascendant = ascendant:getParent()
  end
end

--- @export
return {
  Element = Element,
}

