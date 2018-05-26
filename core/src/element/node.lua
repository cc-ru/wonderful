-- Copyright 2018 the wonderful GUI project authors
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

--- Tree node classes.
-- @module wonderful.element.node

local class = require("lua-objects")

--- The node class that can't store other child nodes.
-- @see wonderful.element.node.ParentNode
local ChildNode = class(nil, {name = "wonderful.element.node.ChildNode"})

--- The node class that can't store other child nodes.
-- @type ChildNode

--- The reference to the parent node. May be absent.
-- @field ChildNode.parentNode

--- The reference to the root node. May be absent.
-- @field ChildNode.rootNode

--- Whether the node has a parent node.
-- @field ChildNode.hasParentNode

--- The tree level.
-- @field ChildNode.level

--- Construct a new instance.
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

function ChildNode.__getters:level()
  return self.hasParentNode and (self.parentNode.level + 1) or 0
end

---
-- @section end

--- The node class that can store child nodes.
-- @see wonderful.element.node.ChildNode
local ParentNode = class(
  ChildNode,
  {name = "wonderful.element.node.ParentNode"}
)

--- The node class that can store child nodes.
-- @type ParentNode

--- The child nodes.
-- @field ParentNode.childNodes

--- `true` if the node has child nodes.
-- @field ParentNode.hasChildNodes

--- Construct a new node.
function ParentNode:__new__()
  self.childNodes = {}
end

--- Insert a node at a given index.
-- @tparam int index the index
-- @param node the node.
function ParentNode:insertChild(index, node)
  if node.hasParentNode then
    node.parentNode:removeChild(node.index)
  end

  node.parentNode = self
  node.rootMemo = self.rootNode

  table.insert(self.childNodes, index, node)

  self:updateIndeces()
end

--- Remove a node at a given index.
-- @tparam int index the index
-- @return `false` or the removed node
function ParentNode:removeChild(index)
  if not self.childNodes[index] then
    return false
  end

  local node = table.remove(self.childNodes, index)

  node.parentNode = nil
  node.rootMemo = nil
  node.index = nil

  self:updateIndeces()

  return node
end

--- Prepend a node.
-- @param child the node
function ParentNode:prependChild(child)
  self:insertChild(1, child)
end

--- Append a node.
-- @param child the node
function ParentNode:appendChild(child)
  self:insertChild(#self.childNodes + 1, child)
end

--- Replace a node at a given index.
-- @tparam int index the index
-- @param child the node
-- @return `false` or the replaced node
function ParentNode:replaceChild(index, child)
  local old = self:removeChild(index)

  if not old then
    return false
  end

  self:insertChild(index, child)
  return old
end

function ParentNode:updateIndeces()
  for i, node in pairs(self.childNodes) do
    node.index = i
  end
end

function ParentNode.__getters:hasChildNodes()
  return #self.childNodes > 0
end

---
-- @export
return {
  ChildNode = ChildNode,
  ParentNode = ParentNode,
}

