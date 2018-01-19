local class = require("lua-objects")

local node = require("wonderful.component.node")
local geometry = require("wonderful.geometry")
local event = require("wonderful.event")

local Element = class({node.Node, event.EventTarget},
                      {name = "wonderful.component.element.Element"})

function Element:__new__()
  -- Root node relative positions
  self.calculatedBox = Box()
  self.requestBox = Box()
  self.attributes = {}
  self.parameters = {}
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
    Element, {name = "wonderful.component.element.LeafElement"})

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

