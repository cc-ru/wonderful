local class = require("lua-objects")

local node = require("wonderful.component.node")
local event = require("wonderful.event")

local Element = class({node.Node, event.EventTarget},
                      {name = "wonderful.component.element.Element"})

-- TODO                      

local LeafElement = class({node.LeafNode, event.EventTarget},
                      {name = "wonderful.component.element.LeafElement"})

-- TODO                      

return {
  Element = Element,
  LeafElement = LeafElement
}

