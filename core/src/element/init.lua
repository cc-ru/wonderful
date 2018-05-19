--- The @{wonderful.element.LeafElement} and @{wonderful.element.Element} classes.
-- @module wonderful.element

local class = require("lua-objects")

local attribute = require("wonderful.element.attribute")
local event = require("wonderful.event")
local geometry = require("wonderful.geometry")
local layout = require("wonderful.layout")
local node = require("wonderful.element.node")
local stack = require("wonderful.element.stack")

local PropRef = require("wonderful.style").PropRef
local VBoxLayout = require("wonderful.layout.box").VBoxLayout

local LeafElement = class(
  {node.ChildNode, event.EventTarget, layout.LayoutItem},
  {name = "wonderful.element.LeafElement"}
)

function LeafElement:__new__()
  self.attributes = {}

  self:superCall(node.ChildNode, "__new__")
  self:superCall(event.EventTarget, "__new__")

  self.calculatedBox = geometry.Box()
end

function LeafElement:render(fbView)
  -- hint
end

function LeafElement:set(attribute)
  self.attributes[attribute.key] = attribute
end

function LeafElement:get(key)
  return self.attributes[key]
end

function LeafElement:getCapturingParent()
  return self.parentNode
end

function LeafElement:getBubblingChildren()
  return {}
end

function LeafElement:sizeHint()
  return 0, 0
end

function LeafElement:propRef(name, default)
  return PropRef(self, name, default)
end

function LeafElement:getMargin()
  return self:get("margin") or attribute.Margin()
end

function LeafElement:getStretch()
  return (self:get("stretch") or attribute.Stretch()).value
end

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
  local position = self:get("position")
  return position and position:isStatic() or true
end

function LeafElement.__getters:viewport()
  return self.parentNode.viewport:intersection(self.calculatedBox)
end

function LeafElement.__getters:isFreeTree()
  return not self.rootNode:isa(require("wonderful.element.document").Document)
end

local Element = class({LeafElement, node.ParentNode, layout.LayoutContainer},
                      {name = "wonderful.element.Element"})

function Element:__new__()
  self:superCall(LeafElement, "__new__")
  self:superCall(node.ParentNode, "__new__")

  self.layout = VBoxLayout()
end

function Element:getBubblingChildren()
  return self.childNodes
end

function Element:getLayoutItems()
  return self.childNodes
end

function Element:getLayoutPadding()
  return self:get("padding") or attribute.Padding()
end

function Element:getLayoutBox()
  local x, y, w, h = self.calculatedBox:unpack()
  local scrollBox = self:get("scrollBox")

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

function Element:insertChild(index, child)
  self:superCall(node.ParentNode, "insertChild", index, child)

  if child.isStaticPositioned then
    self.stackingContext:insertStatic(self.stackingIndex + index, child)
  else
    local zIndex = child:get("zIndex")

    self.stackingContext:insertIndexed(
      self.stackingIndex + index,
      zIndex and zIndex.value or 1,
      child
    )
  end

  if child._stackingContext then
    child._stackingContext:mergeInto(self.stackingContext, child.stackingIndex)
    child._stackingContext = nil
  end

  self:recompose()
end

function Element:removeChild(index)
  local ret = self:superCall(node.ParentNode, "removeChild", index)

  if ret.isStaticPositioned then
    self.stackingContext:removeStatic(self.stackingIndex + index)
  else
    local zIndex = child:get("zIndex")

    self.stackingContext:removeIndexed(
      self.stackingIndex + index,
      zIndex and zIndex.value or 1
    )
  end

  self:recompose()
  return ret
end

function Element:sizeHint()
  local width, height = self.layout:sizeHint(self)
  local padding = self:getLayoutPadding()
  return width + padding.l + padding.r,
         height + padding.t + padding.b
end

function Element:setScrollBox(x, y, w, h)
  self:set(attribute.ScrollBox(x, y, w, h))
  self:recompose()
end

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

function Element.__getters:stackingContext()
  if self.parentNode then
    return self.parentNode.stackingContext
  else
    if not self._stackingContext then
      self._stackingContext = stack.StackingContext()
      self.stackingIndex = 0
    end

    return self._stackingContext
  end
end

function Element.__getters:isLeaf()
  return false
end

return {
  LeafElement = LeafElement,
  Element = Element,
}

