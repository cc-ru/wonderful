local class = require("lua-objects")

local geometry = require("wonderful.geometry")
local layout = require("wonderful.layout")
local event = require("wonderful.event")
local node = require("wonderful.component.node")

local Element = class({node.Node, event.EventTarget},
                      {name = "wonderful.component.element.Element"})

function Element:__new__()
  -- Root node relative positions
  self.calculatedBox = Box()
  self.attributes = {}
  self.parameters = {}
  self.layout = layout.VBoxLayout()
end

function Element:getCapturingParent()
  return self.parentNode
end

function Element:getBubblingChildren()
  return self.childNodes
end

function Element:appendChild(node, at)
  self:superCall(node.Node, "appendChild", node, at)
  self.layout:recompose(self)
end

function Element:removeChild(at)
  local ret = self:superCall(node.Node, "removeChild", at)
  self.layout:recompose(self)
  return ret
end

function Element:replaceChild(at, new)
  local ret = self:superCall(node.Node, "replaceChild", at, new)
  self.layout:recompose(self)
  return ret
end

function Element.__getters:isLeaf()
  return false
end

function Element.__getters:style()
  return self.rootNode.globalStyle
end

function Element.__getters:renderer()
  return self.rootNode.globalRenderer
end

function Element.__getters:renderTarget()
  return self.rootNode.globalRenderTarget
end

local LeafElement = class(
  Element,
  {name = "wonderful.component.element.LeafElement"}
)

function LeafElement:__new__()
  self:superCall(Element, "__new__")
  self.layout = nil
end

function LeafElement:appendChild()
  error("LeafElement can not have any elements")
end

function LeafElement:removeChild()
  error("LeafElement can not have any elements")
end

function LeafElement:replaceChild()
  error("LeafElement can not have any elements")
end

function LeafElement.__getters:isLeaf()
  return true
end

return {
  Element = Element,
  LeafElement = LeafElement
}

