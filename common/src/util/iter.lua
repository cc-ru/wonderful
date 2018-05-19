--- Various iterator utilities.
-- @module wonderful.util.iter

local function wrap(iter, state, var)
  return {
    iter = iter,
    state = state,
    var = var
  }
end

local function ipairsSorted(t, rev)
  local keys = {}

  for k, v in pairs(t) do
    table.insert(keys, k)
  end

  table.sort(keys, rev and function(a, b)
    return a > b
  end or nil)

  local i = 1

  return function()
    if keys[i] then
      i = i + 1
      return i - 1, t[keys[i - 1]]
    end
  end
end

local function ipairsRev(table)
  local i = #table

  return function()
    if table[i] then
      i = i - 1
      return i + 1, table[i + 1]
    end
  end
end

local function chain(...)
  local chain = {...}
  local i = 1

  local function continue()
    local o = {chain[i].iter(chain[i].state, chain[i].var)}
    chain[i].var = o[1]

    if o[1] == nil then
      i = i + 1

      if not chain[i] then
        return
      else
        return continue()
      end
    end

    return table.unpack(o)
  end

  return continue
end

return {
  wrap = wrap,
  ipairsSorted = ipairsSorted,
  ipairsRev = ipairsRev,
  chain = chain,
}

