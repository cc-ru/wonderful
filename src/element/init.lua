local class = require("lua-objects")

local attribute = require("wonderful.element.attribute")
local event = require("wonderful.event")
local geometry = require("wonderful.geometry")
local layout = require("wonderful.layout")
local node = require("wonderful.element.node")

local VBoxLayout = require("wonderful.layout.box").VBoxLayout

local LeafElement = class(
  {node.ChildNode, event.EventTarget, layout.LayoutItem},
  {name = "wonderful.element.LeafElement"}
)

function LeafElement:__new__()
  self:superCall(node.ChildNode, "__new__")
  self:superCall(event.EventTarget, "__new__")

  self.calculatedBox = geometry.Box()
  self.attributes = {}
end

function LeafElement:render(bufferView)
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

function LeafElement:getMargin()
  return self:get("margin") or attribute.Margin()
end

function LeafElement:boxCalculated(new)
  self.calculatedBox = new
end

function LeafElement.__getters:style()
  return self.rootNode.globalStyle
end

function LeafElement.__getters:renderer()
  return self.rootNode.globalRenderer
end

function LeafElement.__getters:renderTarget()
  return self.rootNode.globalRenderTarget
end

function LeafElement.__getters:isLeaf()
  return true
end

function LeafElement.__getters:isStaticPositioned()
  local position = self:get("position")
  return position and position:isStatic() or true
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
  return self.calculatedBox
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

  self.layout:recompose(self)
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

  self.layout:recompose(self)
  return ret
end

function Element:sizeHint()
  local width, height = self.layout:sizeHint()
  local padding = self:getLayoutPadding()
  return width + padding.l + padding.r,
         height + padding.t + padding.b
end

function Element.__getters:stackingContext()
  return self.parentNode.stackingContext
end

function Element.__getters:isLeaf()
  return false
end

return {
  LeafElement = LeafElement,
  Element = Element
}

