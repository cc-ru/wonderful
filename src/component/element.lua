local class = require("lua-objects")

local geometry = require("wonderful.geometry")
local layout = require("wonderful.layout")
local VBoxLayout = require("wonderful.layout.box").VBoxLayout
local event = require("wonderful.event")
local node = require("wonderful.component.node")

local LeafElement = class(
  {node.ChildNode, event.EventTarget, layout.LayoutItem},
  {name = "wonderful.component.element.LeafElement"}
)

function LeafElement:__new__()
  self:superCall(node.ChildNode, "__new__")
  self:superCall(event.EventTarget, "__new__")

  self.calculatedBox = geometry.Box()
  self.attributes = {}
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
  return self.attributes.margin or geometry.Margin(2, 1, 2, 1)
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

local Element = class({LeafElement, node.ParentNode, layout.LayoutContainer},
                      {name = "wonderful.component.element.Element"})

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
  return self.attributes.padding or geometry.Padding(0, 0, 0, 0)
end

function Element:getLayoutBox()
  return self.calculatedBox 
end

function Element:appendChild(index, child)
  self:superCall(node.ParentNode, "appendChild", index, child)
  self.stackingContext:insertStatic(self.stackingIndex + index, child)
  self.layout:recompose(self)
end

function Element:removeChild(index)
  local ret = self:superCall(node.ParentNode, "removeChild", index)
  self.stackingContext:removeStatic(self.stackingIndex + index)
  self.layout:recompose(self)
  return ret
end

function Element:sizeHint()
  local width, height = self.layout:sizeHint()
  local padding = self:getLayoutPadding()
  return width + padding.l + padding.r, height + padding.t + padding.b
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

