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

local isin = require("wonderful.util.table").isin

--- The tree node class.
-- @cl Node
local Node = class(nil, {name = "wonderful.element.node.Node"})

--- @type Node

--- Construct a new node.
function Node:__new__()
  self._parentNode = nil
  self._childNodes = {}
  self._indexMap = {}
end

--- Perform left-to-right breadth-first tree traversal.
--
-- If the function returns a non-`nil` value, traversal is stopped, and the
-- returned value is returned.
--
-- @tparam function(node) func the function to call for each node
function Node:lbfsWalk(func)
  local queue = {self}

  while #queue > 0 do
    local node = table.remove(queue, 1)

    local result = func(node)

    if result ~= nil then
      return result
    end

    for _, child in ipairs(node._childNodes) do
      table.insert(queue, child)
    end
  end
end

--- Perform left-to-right pre-order depth-first traversal.
--
-- If the function returns a non-`nil` value, traversal is stopped, and the
-- returned value is returned.
--
-- @tparam function(node) func the function to call for each node
function Node:nlrWalk(func)
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
--
-- @tparam function(node) func the function to call for each node
function Node:rlnWalk(func)
  for i = #self._childNodes, 1, -1 do
    local result = self._childNodes[i]:rlnWalk(func)

    if result ~= nil then
      return result
    end
  end

  return func(self)
end

do
  local function flagWalker(node, func, key, forced)
    local flag = node[key]
    local flagRaised = forced or flag:isRaised()
    local trapSetOff = flagRaised or flag:isSetOff()

    if flagRaised then
      func(node)
    end

    if trapSetOff then
      for _, child in ipairs(node._childNodes) do
        flagWalker(child, func, key, flagRaised)
      end

      flag:reset()
      flag:lower()
    end
  end

  --- Perform left-to-right pre-order depth-first traversal of flagged nodes.
  --
  -- All nodes in the tree must have a @{wonderful.util.flag.TrappedFlag|flag},
  -- which is used to determine whether to descend and process:
  --
  -- - The walker only descends if the flag it raised or its trap is set off.
  -- - The callback is called if the node or its descendant has its flag raised.
  --
  -- @tparam function(node) func the function to call for each node to be
  -- processed
  -- @param key the key by which index nodes to get the flag
  function Node:flagWalk(func, key)
    return flagWalker(self, func, key, false)
  end
end

--- Insert a node at a given index.
--
-- If the node already has a parent, removes that node from its parent
-- beforehand.
--
-- @tparam int index the index
-- @param node the node
function Node:insertChild(index, node)
  if node:hasParent() then
    node._parentNode:removeChild(node)
  end

  node._parentNode = self

  self._indexMap[node] = index

  table.insert(self._childNodes, index, node)

  self:_updateNodeIndeces()
end

--- Remove a node.
-- @tparam int|Node index the index or the node
-- @return[0] the removed node
-- @treturn[1] `false` the node is not a child
function Node:removeChild(index)
  if type(index) ~= "number" then
    index = self._indexMap[index]
  end

  if not self._childNodes[index] then
    return false
  end

  local node = table.remove(self._childNodes, index)

  node._parentNode = nil
  self._indexMap[node] = nil

  self:_updateNodeIndeces()

  return node
end

--- Replace a node at a given index.
-- @tparam int|Node index the index or the node
-- @param child the node
-- @return[0] the replaced node
-- @treturn[1] `false` the node is not a child
function Node:replaceChild(index, child)
  local old = self:removeChild(index)

  if not old then
    return false
  end

  self:insertChild(index, child)

  return old
end

function Node:_updateNodeIndeces()
  for i, node in pairs(self._childNodes) do
    self._indexMap[node] = i
  end
end

--- Check whether the node has children.
-- @treturn boolean
function Node:hasChildren()
  return #self._childNodes > 0
end

--- Get the parent node.
-- @return[1] the parent node
-- @treturn[2] `nil` the node has no parent
function Node:getParent()
  return self._parentNode
end

--- Get the table of the node's children.
-- @treturn table
function Node:getChildren()
  return self._childNodes
end

--- Get the root node.
-- @return the root node
function Node:getRoot()
  local cur = self

  while true do
    if cur:hasParent() then
      cur = cur:getParent()
    else
      return cur
    end
  end
end

--- Check whether the node has a parent.
-- @treturn boolean
function Node:hasParent()
  return not not self._parentNode
end

--- Calculate the depth level of the node in the tree.
--
-- The root's level is `0`; its children have the level of `1`, and so on.
--
-- @treturn int
function Node:getLevel()
  return self:hasParent() and (self._parentNode:getLevel() + 1) or 0
end

--- Get the index of a child in the list.
-- @param child the child
-- @treturn[1] int the index
-- @treturn[2] nil the node has no parent
function Node:getIndex(child)
  return select(2, isin(child, self:getChildren()))
end

--- @section end

--- A mixin class that adds the methods `appendChild` and `prependChild`.
--
-- If you extend from this class, you have to implement methods `insertChild`
-- and `getChildren` yourself.
--
-- @cl wonderful.element.node.ListMixin
local ListMixin = class(nil, {name = "wonderful.element.node.ListMixin"})

--- @type ListMixin

--- Prepend a node.
--
-- `node:prependChild(...)` is equivalent to `node:insertChild(1, ...)`.
function ListMixin:prependChild(...)
  self:insertChild(1, ...)
end

--- Append a node.
--
-- `node:appendChild(...)` is equivalent to
-- `node:insertChild(#node:getChildren() + 1, ...)`.
function ListMixin:appendChild(...)
  self:insertChild(#self:getChildren() + 1, ...)
end

--- @export
return {
  Node = Node,
  ListMixin = ListMixin,
}

