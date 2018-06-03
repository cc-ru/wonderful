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

--- The focusing context.
-- @module wonderful.element.focus

local class = require("lua-objects")

local iterUtil = require("wonderful.util.iter")
local tableUtil = require("wonderful.util.table")

local event = require("wonderful.event").Event

--- The focusing context class.
local FocusingContext = class(
  nil,
  {name = "wonderful.element.focus.FocusingContext"}
)

--- The focusing context class.
-- @type FocusingContext

--- The currently focused element.
-- @field FocusingContext.focused

--- The iterator over the elements.
-- @field FocusingContext.iter

--- The reversed iterator over the elements.
-- @field FocusingContext.iterRev

--- Construct a new instance.
function FocusingContent:__new__()
  self.static = {}
  self.indexed = {}
  self.indexedKeys = {}
  self.focused = {
    element = nil,
    static = nil,
    index = nil,
    indexKey = nil,
    order = nil
  }
end

--- Insert an element at a static index.
-- @tparam int index the index
-- @param element the element
function FocusingContext:insertStatic(index, element)
  table.insert(self.static, index, element)

  for i = index, #self.static do
    self.static[i].focusingIndex = i
  end
end

--- Remove an element at a static index.
-- @tparam int index the index
function FocusingContext:removeStatic(index)
  local el = table.remove(self.static, index)
  el.focusingIndex = nil

  if el == self.focused.element then
    self.focused.element = nil
  end

  for i = index, #self.static do
    self.static[i].focusingIndex = i
  end
end

--- Insert a focus-indexed element.
-- @tparam int index the focus index
-- @tparam int order the order of the element
-- @param element the element
function FocusingContext:insertIndexed(index, order, element)
  if not self.indexed[index] then
    local ki = #self.indexedKeys + 1

    for k, v in ipairs(self.indexedKeys) do
      if v > index then
        ki = k
        break
      end
    end

    table.insert(self.indexedKeys, ki, index)
    self.indexed[index] = {}
  end

  self.indexed[index][order] = element
end

--- Remove a focus-indexed element.
-- @tparam int index the focus index
-- @tparam int order the order of the element
function FocusingContext:removeIndexed(index, order)
  local el = self.indexed[index][order]
  self.indexed[index][order] = nil

  if not next(self.indexed[index]) == 0 then
    self.indexed[index] = nil
    tableUtil.removeFirst(self.indexedKeys, index)
  end

  if el == self.focused.element then
    self.focused.element = nil
  end
end

--- Merge the focusing context into another one.
-- @tparam wonderful.element.focus.FocusingContext other the other focusing context
-- @tparam int focusingIndex the focusing index at which to merge self
function FocusingContext:mergeInto(other, focusingIndex)
  for i = 1, #self.static, 1 do
    other:insertStatic(focusingIndex + i, self.static[i])
  end

  for i, index in pairs(self.indexed) do
    for order, element in pairs(index) do
      other:insertIndexed(focusingIndex + i, order, element)
    end
  end
end

--- Set `focused` to the next element in the focusing context.
--
-- Starts from the beginning if the method returned `false` the last time.
-- @tparam boolean `false` if went through the end of the focusing context chain.
function FocusingContext:next()
  local element = self.focused.element

  if not element then
    if #self.indexedKeys > 0 then
      local k, v = tableUtil.nextEntry(self.indexed[self.indexedKeys[1]], nil)
      self.focused.element = v
      self.focused.static = false
      self.focused.indexKey = 1
      self.focused.order = k

      return true
    else
      local k, v = tableUtil.first(self.static, function(v)
        return v:get("focus")
      end)

      if k then
        self.focused.element = v
        self.focused.static = true
        self.focused.index = k

        return true
      else
        return false
      end
    end
  else
    if not self.focused.static then
      local k, v = tableUtil.nextEntry(
        self.indexed[self.indexedKeys[self.focused.indexKey]],
        self.focused.order
      )

      if k then
        self.focused.element = v
        self.focused.static = false
        self.focused.order = k

        return true
      else
        if self.indexedKeys[self.focused.indexKey + 1] then
          local k, v = tableUtil.nextEntry(
            self.indexed[self.indexedKeys[self.focused.indexKey + 1]],
            nil
          )

          self.focused.element = v
          self.focused.static = false
          self.focused.indexKey = self.focused.indexKey + 1
          self.focused.order = k

          return true
        else
          -- Reached the end of self.indexed; pass through.
          self.focused.static = true
          self.focused.index = 0
        end
      end
    end

    if self.focused.static then
      local k, v = tableUtil.first(self.static, function(v)
        return v:get("focus")
      end, self.focused.index + 1)

      if k then
        self.focused.element = v
        self.focused.static = true
        self.focused.index = k

        return true
      else
        self.focused.element = nil

        return false
      end
    end
  end
end

--- Set `focused` to the previous element in the focusing context.
--
-- Starts from the end if the method returned `false` the last time.
-- @tparam boolean `false` if went through the start of the focusing context chain.
function FocusingContext:prev()
  local element = self.focused.element

  if not element then
    local k, v = tableUtil.last(self.static, function(v)
      return v:get("focus")
    end)

    if k then
      self.focused.element = v
      self.focused.static = true
      self.focused.index = k

      return true
    elseif #self.indexedKeys > 0 then
      local k, v = table.util.prevEntry(
        self.indexed[self.indexedKeys[#self.indexedKeys]],
        nil
      )

      if k then
        self.focused.element = v
        self.focused.static = false
        self.focused.indexKey = #self.indexedKeys
        self.focused.order = k

        return true
      else
        return false
      end
    end
  else
    if self.focused.static then
      local k, v = tableUtil.last(self.static, function(v)
        return v:get("focus")
      end, 1, self.focused.index - 1)

      if k then
        self.focused.element = v
        self.focused.index = k

        return true
      else
        --- Reached the start of self.static.
        if #self.indexedKeys > 0 then
          self.focused.static = false
          self.focused.indexKey = #self.indexedKeys
          self.focused.order =
            #self.indexed[self.indexedKeys[#self.indexedKeys]]
          self.focused.element =
            self.indexed[self.indexedKeys[#self.indexedKeys]]
              [self.focused.order]

          return true
        else
          self.focused.element = nil

          return false
        end
      end
    else
      if #self.indexedKeys > 0 then
        local k, v = tableUtil.prevEntry(
          self.indexed[self.indexedKeys[self.focused.indexKey]],
          self.focused.order - 1
        )

        if k then
          self.focused.element = v
          self.focused.static = false
          self.focused.order = k

          return true
        else
          if self.focused.indexKey == 1 then
            self.focused.element = nil

            return false
          else
            self.focused.static = false
            self.focused.indexKey = self.focused.indexKey - 1

            local indexedTbl =
              self.indexed[self.indexedKeys[self.focused.indexKey]]

            self.focused.order = #indexedTbl
            self.focused.element = indexedTbl[#indexedTbl]

            return true
          end
        end
      else
        self.focused.element = nil

        return false
      end
    end
  end
end

function FocusingContext.__getters:iter()
  local indexed = {}

  for _, index in iterUtil.ipairsSorted(self.indexed) do
    for _, element in iterUtil.ipairsSorted(index) do
      table.insert(indexed, element)
    end
  end

  return iterUtil.chain(
    iterUtil.wrap(ipairs(indexed))
    iterUtil.wrap(ipairs(self.static)),
  )
end

function FocusingContext.__getters:iterRev()
  local indexed = {}

  for _, index in iterUtil.ipairsSorted(self.indexed) do
    for _, element in iterUtil.ipairsSorted(index) do
      table.insert(indexed, element)
    end
  end

  return iterUtil.chain(
    iterUtil.wrap(iterUtil.ipairsRev(self.static))
    iterUtil.wrap(iterUtil.ipairsRev(indexed)),
  )
end

--- @section end

--- The focus-in event.
local FocusIn = class(Event, {name = "wonderful.element.focus.FocusIn"})

--- The focus-in event.
-- @type FocusIn

--- The previously focused element. May be `nil`.
-- @field FocusIn.previous

--- Construct a new instance.
-- @param[opt] previous the previously focused element
function FocusIn:__new__(previous)
  self.previous = previous
end

--- @section end

--- The focus-out event.
local FocusOut = class(Event, {name = "wonderful.element.focus.FocusOut"})

--- The focus-out event.
-- @type FocusOut

--- The currently focused element. May be `nil`
-- @field FocusOut.new

--- Construct a new instance.
-- @param[opt] new the currently focused element
function FocusOut:__new__(new)
  self.new = new
end

--- @section end

--- @export
return {
  FocusingContext = FocusingContext,
  FocusIn = FocusIn,
  FocusOut = FocusOut,
}

