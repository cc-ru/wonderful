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

--- Whether static positioning is used.
-- @field LeafElement.isStaticPositioned

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
end

--- Render the element.
-- @tparam wonderful.buffer.BufferView fbView a view on the framebuffer
function LeafElement:render(fbView)
  -- hint
end

--- Set an attribute.
--
-- If a class is passed (rather than its instance), the attribute is unset.
-- @tparam wonderful.element.attribute.Attribute attribute the attribute
-- @return self
-- @see wonderful.element.LeafElement:get
-- @usage
-- -- Sets an attribute.
-- element:set(Attribute("test"))
--
-- -- Unsets an attribute.
-- element:set(Attribute)
function LeafElement:set(attribute)
  local previous = self.attributes[attribute.class]
  local new = attribute

  if new.is_class then
    new = nil
  end

  self.attributes[attribute.class] = new

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
  self.calculatedBox = new
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

function LeafElement.__getters:isStaticPositioned()
  return self:get(attribute.Position, true):isStatic()
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
local Element = class({LeafElement, node.ParentNode, layout.LayoutContainer},
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
end

function Element:getChildEventTargets()
  return self.childNodes
end

function Element:getLayoutItems()
  return self.childNodes
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

  self:recompose()
end

--- Removes a child at a given index.
-- @tparam int index the index
-- @return `false` or the removed element
function Element:removeChild(index)
  local child = self:superCall(node.ParentNode, "removeChild", index)

  if not child then
    return false
  end

  self:recompose()

  return child
end

function Element:sizeHint()
  local width, height = self.layout:sizeHint(self)
  local padding = self:getLayoutPadding()
  return width + padding.l + padding.r,
         height + padding.t + padding.b
end

--- Recompose the element, calculating boxes for its children.
function Element:recompose()
  if self.isFreeTree then
    return
  end

  self.layout:recompose(self)

  for _, element in pairs(self.childNodes) do
    if element:isa(Element) then
      element:recompose()
    end
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

