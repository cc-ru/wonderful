local class = require("lua-objects")

local ChildNode = class(nil, {name = "wonderful.element.node.ChildNode"})

function ChildNode:__new_()
  self.parentNode = nil
end

function ChildNode.__getters:rootNode()
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

function ChildNode.__getters:hasParentNode()
  return not not self.parentNode
end

local ParentNode = class(nil, {name = "wonderful.element.node.ParentNode"})

function ParentNode:__new__()
  self.childNodes = {}
end

function ChildNode.__getters:level()
  return self.hasParentNode and (self.parentNode.level + 1) or 0
end

function ParentNode:insertChild(index, node)
  if node.hasParentNode then
    node.parentNode:removeChild(node.index)
  end

  node.parentNode = self
  node.rootMemo = self.rootNode
  node.index = index

  table.insert(self.childNodes, node.index, node)
end

function ParentNode:removeChild(index)
  local node = table.remove(self.childNodes, index)

  node.parentNode = nil
  node.rootMemo = nil
  node.index = nil

  return node
end

function ParentNode:prependChild(child)
  self:insertChild(1, child)
end

function ParentNode:appendChild(child)
  self:insertChild(#self.childNodes + 1, child)
end

function ParentNode:replaceChild(index, child)
  local old = self:removeChild(index)
  self:insertChild(index, child)
  return old
end

function ParentNode.__getters:hasChildNodes()
  return #self.childNodes > 0
end

return {
  ChildNode = ChildNode,
  ParentNode = ParentNode,
}

