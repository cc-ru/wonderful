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

--- Various iterator utilities.
-- @module wonderful.util.iter

--- Wrap an `ipairs` or `pairs` iterator.
-- @tparam function iter an iterator
-- @param state a state value
-- @param var the last value
-- @treturn table a wrapped iterator
local function wrap(iter, state, var)
  return {
    iter = iter,
    state = state,
    var = var
  }
end

--- Create a sorted iterator over a sequence.
-- @tparam table t a sequence
-- @tparam[opt=false] boolean rev whether to invert the sorting function
-- @treturn function an iterator
local function ipairsSorted(t, rev)
  local keys = {}

  for k in pairs(t) do
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

--- Create a reversed iterator over a sequence.
-- @tparam table table a sequence
-- @treturn function an iterator
-- @treturn table the table
-- @treturn int the initial value
local function ipairsRev(table)
  return function(tbl, i)
    local k = i - 1

    if tbl[k] then
      return k, tbl[k]
    else
      return
    end
  end, table, #table + 1
end

--- Chain several wrapped iterators.
-- When an iterator ends, the next one is used.
-- @param ... wrapped iterators to chain
-- @treturn function a chained iterator
-- @usage chain(wrap(ipairs(a)), wrap(ipairs(b)))
-- @see wonderful.util.iter.chain
local function chain(...)
  local chained = {...}
  local i = 1

  local function continue()
    local o = table.pack(chained[i].iter(chained[i].state, chained[i].var))
    chained[i].var = o[1]

    if o[1] == nil then
      i = i + 1

      if not chained[i] then
        return
      else
        return continue()
      end
    end

    return table.unpack(o, 1, o.n)
  end

  return continue
end

---
-- @export
return {
  wrap = wrap,
  ipairsSorted = ipairsSorted,
  ipairsRev = ipairsRev,
  chain = chain,
}

