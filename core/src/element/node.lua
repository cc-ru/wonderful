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

--- Construct a new instance.
function ChildNode:__new_()
  self._parentNode = nil
end

--- Perform left-to-right breadth-first tree traversal.
--
-- If the function returns a non-`nil` value, traversal is stopped, and the
-- returned value is returned.
-- @tparam function(node) func the function to call for each node
function ChildNode:lbfsWalk(func)
  return func(self)
end

--- Perform left-to-right pre-order depth-first traversal.
--
-- If the function returns a non-`nil` value, traversal is stopped, and the
-- returned value is returned.
-- @tparam function(node) func the function to call for each node
function ChildNode:nlrWalk(func)
  return func(self)
end

--- Perform right-to-left post-order depth-first traversal.
--
-- If the function returns a non-`nil` value, traversal is stopped, and the
-- returned value is returned.
-- @tparam function(node) func the function to call for each node
function ChildNode:rlnWalk(func)
  return func(self)
end

function ChildNode:getParent()
  return self._parentNode
end

function ChildNode:getRootNode()
  if self._rootMemo then
    return self._rootMemo
  end

  local cur = self

  while true do
    if cur._parentNode then
      cur = cur._parentNode
    else
      self._rootMemo = cur
      return cur
    end
  end
end

function ChildNode:hasParentNode()
  return not not self._parentNode
end

function ChildNode:getLevel()
  return self:hasParentNode() and (self._parentNode:getLevel() + 1) or 0
end

--- Get the index of the node in the parent's child list.
-- @treturn[1] int the index
-- @treturn[2] nil the node has no parent
function ChildNode:getIndex()
  return self._index
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

--- Construct a new node.
function ParentNode:__new__()
  self._childNodes = {}
end

function ParentNode:getChildren()
  return self._childNodes
end

--- Perform left-to-right breadth-first tree traversal.
--
-- If the function returns a non-`nil` value, traversal is stopped, and the
-- returned value is returned.
--
-- @tparam function(node) func the function to call for each node
function ParentNode:lbfsWalk(func)
  local queue = {self}

  while #queue > 0 do
    local node = table.remove(queue, 1)

    local result = func(node)

    if result ~= nil then
      return result
    end

    if node:isa(ParentNode) then
      for _, child in ipairs(node._childNodes) do
        table.insert(queue, child)
      end
    end
  end
end

--- Perform left-to-right pre-order depth-first traversal.
--
-- If the function returns a non-`nil` value, traversal is stopped, and the
-- returned value is returned.
-- @tparam function(node) func the function to call for each node
function ParentNode:nlrWalk(func)
  local result = func(self)

  if result ~= nil then
    return result
  end

  for _, child in ipairs(self._childNodes) do
    result = child:nlrWalk(func)

    if result ~= nil then
      return result
    end
  end
end

--- Perform right-to-left post-order depth-first traversal.
--
-- If the function returns a non-`nil` value, traversal is stopped, and the
-- returned value is returned.
-- @tparam function(node) func the function to call for each node
function ParentNode:rlnWalk(func)
  for i = #self._childNodes, 1, -1 do
    local result = self._childNodes[i]:rlnWalk(func)

    if result ~= nil then
      return result
    end
  end

  return func(self)
end

--- Insert a node at a given index.
-- @tparam int index the index
-- @param node the node.
function ParentNode:insertChild(index, node)
  if node:hasParentNode() then
    node._parentNode:removeChild(node._index)
  end

  node._parentNode = self
  node._rootMemo = self._rootNode

  table.insert(self._childNodes, index, node)

  self:updateIndeces()
end

--- Remove a node at a given index.
-- @tparam int index the index
-- @return `false` or the removed node
function ParentNode:removeChild(index)
  if not self._childNodes[index] then
    return false
  end

  local node = table.remove(self._childNodes, index)

  node._parentNode = nil
  node._rootMemo = nil
  node._index = nil

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
  self:insertChild(#self._childNodes + 1, child)
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
  for i, node in pairs(self._childNodes) do
    node._index = i
  end
end

function ParentNode:hasChildNodes()
  return #self._childNodes > 0
end

---
-- @export
return {
  ChildNode = ChildNode,
  ParentNode = ParentNode,
}

