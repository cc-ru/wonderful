local class = require("lua-objects")

local Node = class(nil, {name = "wonderful.component.node.Node"})

function Node:__new_()
  self.parentNode = nil
  self.childNodes = {}
end

function Node:appendChild(node, at)
  node.parentNode = self
  table.insert(self.childNodes, at or (#self.childNodes + 1), node)
end

function Node:removeChild(at)
  local node = table.remove(self.childNodes, at)
  node.parentNode = nil
end

function Node:replaceChild(at, new)
  local old = self.childNodes[at]
  old.parentNode = nil
  new.parentNode = self
  self.childNodes[at] = new
  return old
end

function Node.__getters:hasChildNodes()
  return #self.childNodes > 0
end

function Node.__getters:hasParentNode()
  return not not self.parentNode
end

function Node.__getters:rootNode()
  local cur = self
  while true do
    if cur.parentNode then
      cur = cur.parentNode
    else
      return cur
    end
  end
end

local LeafNode = class(Node, {name = "wonderful.component.node.LeafNode"})

function LeafNode:appendChild()
  error("LeafNode can contain no children")
end

function LeafNode:removeChild()
  error("LeafNode can contain no children")
end

function LeafNode:replaceChild()
  error("LeafNode can contain no children")
end

