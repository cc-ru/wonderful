local node = require("wonderful.component.node")
local element = require("wonderful.component.element")
local document = require("wonderful.component.document")

return {
  Node = node.Node,
  Element = element.Element,
  LeafElement = element.LeafElement,
  Document = document.Document
}

