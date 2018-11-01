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

--- The @{wonderful.element.Element|Element} class.
-- @module wonderful.element

local class = require("lua-objects")

local event = require("wonderful.event")
local node = require("wonderful.element.node")

local TrappedFlag = require("wonderful.util.flag").TrappedFlag

local function shouldRenderIndexer(element)
  local parent = element:getParent()

  if parent then
    return parent._shouldRender
  end
end

--- The base element class.
-- @cl wonderful.element.Element
-- @extends wonderful.element.node.Node
-- @extends wonderful.event.EventTarget
local Element = class({node.Node, event.EventTarget},
                      {name = "wonderful.element.Element"})

--- @type Element

--- Construct a new element instance.
function Element:__new__(args)
  args = args or {}

  node.Node.__new__(self)
  event.EventTarget.__new__(self)

  -- This has to be here because of the requirement of `Node:flagWalk`.
  -- The flag itself is only raised by widgets, though.
  self._shouldRender = TrappedFlag(shouldRenderIndexer, false, false, self)
end

function Element:getParentEventTarget()
  return self:getParent()
end

function Element:getChildEventTargets()
  return self:getChildren()
end

--- Get the tree's @{wonderful.display.Display|display} instance.
-- @treturn[1] wonderful.display.Display the display instance
-- @treturn[2] nil the tree is free
-- @see Element:isFreeTree
function Element:getDisplay()
  -- This method is redefined by `Document` to return the actual value.
  if self:hasParent() then
    return self:getParent():getDisplay()
  end
end

--- Check whether the tree is free, i.e., not rooted at a `Document` instance.
-- @treturn boolean
function Element:isFreeTree()
  -- This `require` can't be moved to the scope above, as that would cause an
  -- import cycle.
  return not self:getRoot():isa(require("wonderful.element.document").Document)
end

function Element:isFocused()
  -- TODO: decide whether it makes any sense to have focusing defined here
  -- rather than in the `Widget` class.
  error("Method Element:isFocused not implemented yet")
end

--- Pretty-print the tree rooted at self into the stream.
--
-- Calls `func` for each element. Returned values are passed to
-- `string.format` and appended to the element line.
--
-- The stream will be automatically closed.
--
-- @tparam function(element) func the function to call
-- @tparam {write=function,close=function} stream the stream
function Element:dumpTree(func, stream)
  stream:write("Dump of tree rooted at " .. tostring(self) .. ":\n")

  self:nlrWalk(function(node)
    stream:write(("%s- %s: %s\n"):format(
      ("  "):rep(node:getLevel() - 1),
      tostring(node),
      string.format(func(node))
    ))
  end)

  stream:write("\n")
  stream:close()
end

--- @export
return {
  Element = Element,
}

