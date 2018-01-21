local class = require("lua-objects")

local ChildNode = class(nil, {name = "wonderful.component.node.ChildNode"})

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

local ParentNode = class(nil, {name = "wonderful.component.node.ParentNode"})

function ParentNode:__new__()
  self.childNodes = {}
end

function ParentNode:appendChild(node, at)
  node.parentNode = self
  node.rootMemo = self.rootNode

  table.insert(self.childNodes, at or (#self.childNodes + 1), node)
end

function ParentNode:removeChild(at)
  local node = table.remove(self.childNodes, at)

  node.parentNode = nil
  node.rootMemo = nil

  return node
end

function ParentNode:replaceChild(at, new)
  local old = self.childNodes[at]

  old.parentNode = nil
  old.rootMemo = nil

  new.parentNode = self
  new.rootMemo = self.rootNode

  self.childNodes[at] = new

  return old
end

function ParentNode.__getters:hasChildNodes()
  return #self.childNodes > 0
end

return {
  ChildNode = ChildNode,
  ParentNode = ParentNode
}

