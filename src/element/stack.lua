local class = require("lua-objects")

local iterUtil = require("wonderful.util.iter")

local StackingContext = class(
  nil,
  {name = "wonderful.element.stack.StackingContext"}
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
  self.indexedCache = nil
end

function StackingContext:removeIndexed(index, order)
  self.indexed[index][order] = nil
  self.indexedCache = nil
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

return {
  StackingContext = StackingContext
}

