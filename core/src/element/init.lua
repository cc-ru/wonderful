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

--- The element's calculated box.
-- @see wonderful.geometry.Box
-- @field LeafElement.calculatedBox

--- The document's style instance. May be absent.
-- @field LeafElement.style

--- The document's display. May be absent.
-- @field LeafElement.display

--- Whether the element is a leaf node.
-- @field LeafElement.isLeaf

--- Whether the element is part of the container's element flow (has the
-- @{wonderful.element.attribute.Position|Position} attribute set to either
-- `"static"` or `"relative"`).
--
-- @field LeafElement.isFlowElement

--- The viewport (the shown area when the container is scrolled).
-- @field LeafElement.viewport

--- Whether the element is part of a free tree.
-- A free tree is a tree without
-- a @{wonderful.element.document.Document|Document} node.
-- @field LeafElement.isFreeTree

--- Construct a new instance.
function LeafElement:__new__()
  self.attributes = {}

  self:superCall(node.ChildNode, "__new__")
  self:superCall(event.EventTarget, "__new__")

  self.calculatedBox = geometry.Box()
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
  self.shouldRedraw = true

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
  if self.shouldRedraw then
    self:_render(fbView)
    self.shouldRedraw = false

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
  local previous = self.attributes[attr.class]
  local new = attr

  if new.is_class then
    new = nil
  end

  self.attributes[attr.class] = new

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
-- print(element:get(Attribute).value)
function LeafElement:get(clazz, default)
  local attr = self.attributes[clazz.class]

  if attr then
    return attr
  elseif default and clazz then
    return clazz()
  else
    return nil
  end
end

function LeafElement:getParentEventTarget()
  return self.parentNode
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
  return self:get(attribute.Stretch, true).value
end

--- Set a new calculated box.
-- @tparam wonderful.geometry.Box new the new box
function LeafElement:boxCalculated(new)
  local position = self:get(attribute.Position, true)

  if position.value == "relative" then
    local bbox = self:get(attribute.BoundingBox)
    new.x = new.x + (bbox and bbox.left or 0)
    new.y = new.y + (bbox and bbox.top or 0)
  end

  self.calculatedBox = new
end

function LeafElement:_notifyParentsOfRenderRequest()
  local ascendant = self.parentNode

  while ascendant do
    ascendant.renderRequestedByChildren = true

    ascendant = ascendant.parentNode
  end
end

function LeafElement.__getters:style()
  return self.rootNode.globalStyle
end

function LeafElement.__getters:display()
  return self.rootNode.globalDisplay
end

function LeafElement.__getters:isLeaf()
  return true
end

function LeafElement.__getters:isFlowElement()
  return self:get(attribute.Position, true):isFlowElement()
end

function LeafElement.__getters:viewport()
  return self.parentNode.viewport:intersection(self.calculatedBox)
end

function LeafElement.__getters:isFreeTree()
  return not self.rootNode:isa(require("wonderful.element.document").Document)
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

--- The layout used to position children.
-- @field Element.layout

--- Whether the element is a leaf node.
-- @field Element.isLeaf

--- Construct a new element instance.
function Element:__new__()
  self:superCall(LeafElement, "__new__")
  self:superCall(node.ParentNode, "__new__")

  self.layout = VBoxLayout()
  self.layout:optimize()

  self.markedToRecompose = true
  self.hasMarkedDescendant = true
end

function Element:getChildEventTargets()
  return self.childNodes
end

function Element:getLayoutItems()
  return coroutine.wrap(function()
    for _, element in ipairs(self.childNodes) do
      if element.isFlowElement then
        coroutine.yield(element)
      end
    end
  end)
end

function Element:getLayoutPadding()
  return self:get(attribute.Padding, true)
end

function Element:getLayoutBox()
  local x, y, w, h = self.calculatedBox:unpack()
  local scrollBox = self:get(attribute.ScrollBox)

  if scrollBox then
    if scrollBox.x then
      x = x + scrollBox.x
    end

    if scrollBox.y then
      y = y + scrollBox.y
    end

    if scrollBox.w then
      w = scrollBox.w
    end

    if scrollBox.h then
      h = scrollBox.h
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
  local width, height = self.layout:sizeHint(self)
  local padding = self:getLayoutPadding()
  return width + padding.l + padding.r,
         height + padding.t + padding.b
end

--- Mark the element to be recomposed when `recompose` is called for it or
-- one of its ascendants.
--
-- @see wonderful.element.Element:recompose
function Element:markToRecompose()
  self.markedToRecompose = true
  self:_markParent()
end

--- Recompose the element: calculate boxes for its children.
--
-- **Does not** recompose self if not marked, unless forced.
--
-- @tparam[opt=false] boolean force whether to force recomposing
-- @see wonderful.element.Element:markToRecompose
function Element:recompose(force)
  if self.isFreeTree then
    return
  end

  if force then
    self.markedToRecompose = true
  end

  if self.markedToRecompose then
    self.layout:recompose(self)
    self:requestRender()

    local bbox, x, y, w, h
    local layoutBox = self:getLayoutBox()
    local calcBox = self.calculatedBox

    for _, element in ipairs(self.childNodes) do
      local position = element:get(attribute.Position, true)

      if not position:isFlowElement() then
        bbox = element:get(attribute.BoundingBox)

        if position.value == "absolute" then
          x, y = layoutBox.x, layoutBox.y
        elseif position.value == "fixed" then
          x, y = calcBox.x, calcBox.y
        end

        w, h = element:sizeHint()

        element:boxCalculated(geometry.Box(
          x + (bbox.left or 0),
          y + (bbox.top or 0),
          bbox.width or w,
          bbox.height or h
        ))
      end
    end
  end

  if self.hasMarkedDescendant or self.markedToRecompose then
    for _, element in pairs(self.childNodes) do
      if element:isa(Element) then
        if self.markedToRecompose then
          element.markedToRecompose = true
        end

        if element.markedToRecompose or element.hasMarkedDescendant then
          element:recompose()
        end
      end
    end
  end

  self.hasMarkedDescendant = false
  self.markedToRecompose = false
end

function Element:_markParent()
  if self.parentNode then
    self.parentNode.hasMarkedDescendant = true
    self.parentNode:_markParent()
  end
end

function Element.__getters:isLeaf()
  return false
end

--- @export
return {
  LeafElement = LeafElement,
  Element = Element,
}

