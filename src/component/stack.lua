local class = require("lua-objects")

local util = require("wonderful.util")

local StackingContext = class(
  nil,
  {name = "wonderful.component.stack.StackingContext"}
)

function StackingContext:__new__()
  self.static = {}
  self.indexed = {}
  self.indexedCache = nil
end

function StackingContext:insertStatic(index, element)
  table.insert(self.static, index, element)

  for i = index, #self.static do
    self.static[i].stackingIndex = i
  end
end

function StackingContext:removeStatic(index)
  local el = table.remove(self.static, index)
  el.stackingIndex = nil
  
  for i = index, #self.static do
    self.static[i].stackingIndex = i
  end
end

function StackingContext:insertIndexed(index, order, element)
  if not self.indexed[index] then
    self.indexed[index] = {}
  end

  self.indexed[index][order] = element
end

function StackingContext:removeIndexed(index, order)
  self.indexed[index][order] = nil
end

function StackingContext.__getters:iter()
  local indexed = {}

  if self.indexedCache then
    indexed = self.indexedCache
  else
    for _, index in util.iter.ipairsSorted(self.indexed) do
      for _, element in util.iter.ipairsSorted(index) do
        table.insert(indexed, element)
      end
    end
  end

  return util.iter.chain(
    util.iter.wrap(ipairs(self.static)),
    util.iter.wrap(ipairs(indexed))
  )
end

function StackingContext.__getters:iterRev()
  local indexed = {}

  if self.indexedCache then
    indexed = self.indexedCache
  else
    for _, index in util.iter.ipairsSorted(self.indexed) do
      for _, element in util.iter.ipairsSorted(index) do
        table.insert(indexed, element)
      end
    end
  end

  return util.iter.chain(
    util.iter.wrap(util.iter.ipairsRev(indexed)),
    util.iter.wrap(util.iter.ipairsRev(self.static))
  )
end

return {
  StackingContext = StackingContext
}

