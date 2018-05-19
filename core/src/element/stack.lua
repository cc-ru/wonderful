--- The stacking context.
-- @module wonderful.element.stack

local class = require("lua-objects")

local iterUtil = require("wonderful.util.iter")

--- The stacking context class.
local StackingContext = class(
  nil,
  {name = "wonderful.element.stack.StackingContext"}
)

--- The stacking context class.
-- @type StackingContext

--- The iterator over the elements.
-- @field StackingContext.iter

--- The reversed iterator over the elements.
-- @field StackingContext.iterRev

--- Construct a new stacking context.
function StackingContext:__new__()
  self.static = {}
  self.indexed = {}
  self.indexedCache = nil
end

--- Insert an element at a static index.
-- @tparam int index the index
-- @param element the element
function StackingContext:insertStatic(index, element)
  table.insert(self.static, index, element)

  for i = index, #self.static do
    self.static[i].stackingIndex = i
  end
end

--- Remove an element at a static index.
-- @tparam int index the index
function StackingContext:removeStatic(index)
  local el = table.remove(self.static, index)
  el.stackingIndex = nil

  for i = index, #self.static do
    self.static[i].stackingIndex = i
  end
end

--- Insert a z-indexed element.
-- @tparam int index the z-index
-- @tparam int order the order of the element
-- @param element the element
function StackingContext:insertIndexed(index, order, element)
  if not self.indexed[index] then
    self.indexed[index] = {}
  end

  self.indexed[index][order] = element
  self.indexedCache = nil
end

--- Remove a z-indexed element.
-- @tparam int index the z-index
-- @tparam int order the order of the element
function StackingContext:removeIndexed(index, order)
  self.indexed[index][order] = nil
  self.indexedCache = nil
end

--- Merge the stacking context into another one.
-- @tparam wonderful.element.stack.StackingContext other the other stacking context
-- @tparam int stackingIndex the stacking index at which to merge self
function StackingContext:mergeInto(other, stackingIndex)
  for i = 1, #self.static, 1 do
    other:insertStatic(stackingIndex + i, self.static[i])
  end

  for i, index in pairs(self.indexed) do
    for order, element in pairs(index) do
      other:insertIndexed(stackingIndex + i, order, element)
    end
  end
end

function StackingContext.__getters:iter()
  local indexed = {}

  if self.indexedCache then
    indexed = self.indexedCache
  else
    for _, index in iterUtil.ipairsSorted(self.indexed) do
      for _, element in iterUtil.ipairsSorted(index) do
        table.insert(indexed, element)
      end
    end
  end

  return iterUtil.chain(
    iterUtil.wrap(ipairs(self.static)),
    iterUtil.wrap(ipairs(indexed))
  )
end

function StackingContext.__getters:iterRev()
  local indexed = {}

  if self.indexedCache then
    indexed = self.indexedCache
  else
    for _, index in iterUtil.ipairsSorted(self.indexed) do
      for _, element in iterUtil.ipairsSorted(index) do
        table.insert(indexed, element)
      end
    end
  end

  return iterUtil.chain(
    iterUtil.wrap(iterUtil.ipairsRev(indexed)),
    iterUtil.wrap(iterUtil.ipairsRev(self.static))
  )
end

---
-- @export
return {
  StackingContext = StackingContext,
}

