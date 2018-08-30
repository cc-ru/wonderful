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

--- The @{wonderful.element.LeafElement|LeafElement} and @{wonderful.element.Element|Element} classes.
-- @module wonderful.element

local class = require("lua-objects")

local attribute = require("wonderful.element.attribute")
local event = require("wonderful.event")
local geometry = require("wonderful.geometry")
local layout = require("wonderful.layout")
local node = require("wonderful.element.node")

local PropRef = require("wonderful.style").PropRef
local VBoxLayout = require("wonderful.layout.box").VBoxLayout

--- The leaf element class, which can't store children.
-- @see wonderful.element.node.ChildNode
-- @see wonderful.event.EventTarget
-- @see wonderful.layout.LayoutItem
local LeafElement = class(
  {node.ChildNode, event.EventTarget, layout.LayoutItem},
  {name = "wonderful.element.LeafElement"}
)

--- The leaf element class, which can't store children.
-- @type LeafElement

--- Construct a new instance.
function LeafElement:__new__()
  self._attributes = {}

  self:superCall(node.ChildNode, "__new__")
  self:superCall(event.EventTarget, "__new__")

  self._calculatedBox = geometry.Box()
  self._focused = false
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
-- @see LeafElement:requestRender
function LeafElement:_render(fbView)
  error("Abstract method LeafElement:_render not implemented")
end

--- Flag the element so that it's rendered the next time `Wonderful:render`
-- is called.
function LeafElement:requestRender()
  self._shouldRedraw = true

  self:_notifyParentsOfRenderRequest()
end

--- Conditionally render the element.
--
-- This method does nothing if the element isn't flagged.
--
-- @tparam wonderful.buffer.BufferView fbView a view on the framebuffer
-- @treturn boolean whether the element was actually rendered
-- @see LeafElement:requestRender
function LeafElement:render(fbView)
  if self._shouldRedraw then
    self:_render(fbView)
    self._shouldRedraw = false

    return true
  end

  return false
end

--- Set an attribute.
--
-- If a class is passed (rather than its instance), the attribute is unset.
-- @tparam wonderful.element.attribute.Attribute attr the attribute
-- @return self
-- @see wonderful.element.LeafElement:get
-- @usage
-- -- Sets an attribute.
-- element:set(Attribute("test"))
--
-- -- Unsets an attribute.
-- element:set(Attribute)
function LeafElement:set(attr)
  local previous = self._attributes[attr.class]
  local new = attr

  if new.is_class then
    new = nil
  end

  self._attributes[attr.class] = new

  if previous then
    previous:onUnset(self, new)
  end

  if new then
    new:onSet(self, previous)
  end

  return self
end

--- Get an attribute by its class.
-- @param clazz the attribute class
-- @tparam[opt=false] boolean default whether to return the default if not found
-- @return the attribute or `nil`
-- @see wonderful.element.LeafElement:set
-- @usage
-- element:set(Attribute("test"))
-- print(element:get(Attribute):get())
function LeafElement:get(clazz, default)
  local attr = self._attributes[clazz.class]

  if attr then
    return attr
  elseif default and clazz then
    return clazz()
  else
    return nil
  end
end

function LeafElement:getParentEventTarget()
  return self:getParent()
end

function LeafElement:getChildEventTargets()
  return {}
end

--- Provide a hint on the element size.
-- @treturn int the width
-- @treturn int the height
function LeafElement:sizeHint()
  return 0, 0
end

--- Create a style property reference.
-- @tparam string name the property name
-- @param default a default value
-- @treturn wonderful.style.PropRef the property reference
-- @see wonderful.style.PropRef
function LeafElement:propRef(name, default)
  return PropRef(self, name, default)
end

--- Get the element's margin.
-- @treturn wonderful.element.attribute.Margin
function LeafElement:getMargin()
  return self:get(attribute.Margin, true)
end

--- Get the element's stretch value.
-- @treturn wonderful.element.attribute.Stretch
function LeafElement:getStretch()
  return self:get(attribute.Stretch, true):get()
end

--- Set a new calculated box.
-- @tparam wonderful.geometry.Box new the new box
function LeafElement:setCalculatedBox(new)
  local position = self:get(attribute.Position, true)

  if position:get() == "relative" then
    local bbox = self:get(attribute.BoundingBox)
    new:setX(new:getX() + (bbox and bbox:getLeft() or 0))
    new:setY(new:getY() + (bbox and bbox:getTop() or 0))
  end

  self._calculatedBox = new
end

function LeafElement:_notifyParentsOfRenderRequest()
  local ascendant = self:getParent()

  while ascendant do
    ascendant._renderRequestedByChildren = true

    ascendant = ascendant:getParent()
  end
end

function LeafElement:getStyle()
  return self:getRootNode()._globalStyle
end

function LeafElement:getDisplay()
  return self:getRootNode()._globalDisplay
end

function LeafElement:isLeaf()
  return true
end

function LeafElement:isFlowElement()
  return self:get(attribute.Position, true):isFlowElement()
end

function LeafElement:getViewport()
  return self:getParent():getViewport():intersection(self._calculatedBox)
end

function LeafElement:isFreeTree()
  return not self:getRootNode()
                 :isa(require("wonderful.element.document").Document)
end

function LeafElement:getCalculatedBox()
  return self._calculatedBox
end

function LeafElement:isFocused()
  return self._focused
end

---
-- @section end

--- The non-leaf element class.
-- @see wonderful.element.LeafElement
-- @see wonderful.element.node.ParentNode
-- @see wonderful.layout.LayoutContainer
local Element = class({node.ParentNode, LeafElement, layout.LayoutContainer},
                      {name = "wonderful.element.Element"})

--- A non-leaf element class.
-- @type Element

--- Construct a new element instance.
function Element:__new__()
  self:superCall(LeafElement, "__new__")
  self:superCall(node.ParentNode, "__new__")

  self:setLayout(VBoxLayout())

  self._markedToRecompose = true
  self._hasMarkedDescendant = true
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
  return self:get(attribute.Padding, true)
end

function Element:getLayoutBox()
  local x, y, w, h = self._calculatedBox:unpack()
  local scrollBox = self:get(attribute.ScrollBox)

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
  self:superCall(node.ParentNode, "insertChild", index, child)

  self:recompose(true)
end

--- Remove a child at a given index.
-- @tparam int index the index
-- @return `false` or the removed element
function Element:removeChild(index)
  local child = self:superCall(node.ParentNode, "removeChild", index)

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
      local position = element:get(attribute.Position, true)

      if not position:isFlowElement() then
        bbox = element:get(attribute.BoundingBox)

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
      if element:isa(Element) then
        if self._markedToRecompose then
          element._markedToRecompose = true
        end

        if element._markedToRecompose or element._hasMarkedDescendant then
          element:recompose()
        end
      end
    end
  end

  self._hasMarkedDescendant = false
  self._markedToRecompose = false
end

function Element:_markParent()
  local ascendant = self:getParent()

  while ascendant do
    ascendant._hasMarkedDescendant = true

    ascendant = ascendant:getParent()
  end
end

function Element:isLeaf()
  return false
end

function Element:setLayout(layout)
  layout:optimize()
  self._layout = layout
end

function Element:getLayout(layout)
  return self._layout
end

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

--- @export
return {
  LeafElement = LeafElement,
  Element = Element,
}

