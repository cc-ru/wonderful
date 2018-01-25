local class = require("lua-objects")

local util = require("wonderful.util")

local StackingContext = class(
  nil,
  {name = "wonderful.component.stack.StackingContext"}
)

function StackingContext:__new__()
  self.static = {}
  self.indexed = {}
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

function StackingContext.__getters:iter()
  -- return util.iter.chain(
  --   util.iter.wrap(ipairs(self.static)),
  --   util.iter.wrap(util.iter.ipairsSorted(self.indexed))
  -- )
  
  return ipairs(self.static)
end

function StackingContext.__getters:iterRev()
  -- return util.iter.chain(
  --   util.iter.wrap(util.iter.ipairsSorted(self.indexed, true)),
  --   util.iter.wrap(util.iter.ipairsRev(self.static))
  -- )

  return util.iter.ipairsRev(self.static)
end

return {
  StackingContext = StackingContext
}

