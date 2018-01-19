local class = require("lua-objects")

local Node = class(nil, {name = "wonderful.component.node.Node"})

function Node:__new_()
  self.parentNode = nil
  self.childNodes = {}
end

function Node:appendChild(node, at)
  node.parentNode = self
  node.rootMemo = self.rootNode

  table.insert(self.childNodes, at or (#self.childNodes + 1), node)
end

function Node:removeChild(at)
  local node = table.remove(self.childNodes, at)

  node.parentNode = nil
  node.rootMemo = nil

  return node
end

function Node:replaceChild(at, new)
  local old = self.childNodes[at]

  old.parentNode = nil
  old.rootMemo = nil

  new.parentNode = self
  new.rootMemo = self.rootNode

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
  if self.rootMemo then
    return self.rootMemo
  end

  local cur = self

  while true do
    if cur.parentNode then
      cur = cur.parentNode
    else
      self.rootMemo = cur
      return cur
    end
  end
end

return {
  Node = Node
}

