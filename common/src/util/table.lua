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

--- Various table utilities.
-- @module wonderful.util.table

--- Create a shallow copy of a table.
-- @tparam table orig a value
-- @treturn table the copy
local function shallowcopy(orig)
  if type(orig) ~= "table" then
    return orig
  end

  local copy = {}

  for k, v in pairs(orig) do
    copy[k] = v
  end

  return copy
end

--- Test two values for equality.
-- If both values are tables, checks whether the left value is a subset of
-- the right value, using `==` to test for equality of table values.
-- @param lhs the left value
-- @param rhs the right value
-- @treturn boolean
local function shalloweq(lhs, rhs)
  if lhs == rhs then
    return true
  end

  if type(lhs) ~= type(rhs) then
    return false
  end

  if type(lhs) ~= "table" then
    return false
  end

  for k, v in pairs(lhs) do
    if not rhs[k] or rhs[k] ~= v then
      return false
    end
  end
end

--- Checks if a table contains a value.
-- @param value a value
-- @tparam table tbl a table
-- @return[1] `true` if the table contains the given value
-- @return[1] the first key which maps to the given value
-- @return[2] `false` if the table doesn't contain the given value
local function isin(value, tbl)
  for k, v in pairs(tbl) do
    if v == value then
      return true, k
    end
  end

  return false
end

--- Create a table that tries to require a submodule when indexed.
-- E. g., `autoimport({}, "test").submodule` tries to
-- `require("test.submodule")` and returns the value if it succeeds.
--
-- If the required value is a table, applies
-- @{wonderful.util.table.autoimport|autoimport} to it.
--
-- @tparam table root an root table
-- @tparam string pkg a root module name
-- @treturn table
local function autoimport(root, pkg)
  return setmetatable(root, {
    __index = function(self, name)
      local success, mod = pcall(require, pkg .. "." .. name)

      if success then
        if type(mod) == "table" and not getmetatable(mod) then
          return autoimport(mod, pkg .. "." .. name)
        else
          return mod
        end
      end
    end
  })
end

--- Swap the keys and values of a table.
-- @tparam table tbl a table
-- @treturn table a swapped table
-- @raise the table has two keys with the same value
-- @usage
-- local tbl = {13, 19, 20, 45}
-- local swapped = swapPairs(tbl)
-- print(swapped[13]) --> 1
-- print(swapped[1]) --> nil
local function swapPairs(tbl)
  local result = {}

  for k, v in pairs(tbl) do
    if result[v] then
      error("the table has two keys with the same value")
    end

    result[v] = k
  end

  return result
end

--- Calculate the number of entries in a table.
-- @tparam table tbl the table
-- @treturn int the number of entries
local function tableLen(tbl)
  local i = 0

  for _ in pairs(tbl) do
    i = i + 1
  end

  return i
end

--- Get keys of a table.
-- @tparam table tbl the table
-- @treturn table a table of the keys
local function getKeys(tbl)
  local result = {}

  for k in pairs(tbl) do
    result[#result + 1] = k
  end

  return result
end

--- Get an element of a table that follows a previous one.
--
-- If the given key is `nil`, the first element is returned.
-- @tparam table tbl the table
-- @param[opt] key the key of the previous element
-- @return the next key
-- @return the next element
local function nextEntry(tbl, key)
  local keys = {}

  for k in pairs(tbl) do
    if not key or k > key then
      keys[#keys + 1] = k
    end
  end

  table.sort(keys)

  return keys[1], tbl[keys[1]]
end

--- Get an element of a table that precedes a following one.
--
-- If the given key is `nil`, the last element is returned.
-- @tparam table tbl the table
-- @param[opt] key the key of the following element
-- @return the preceding key
-- @return the preceding element
local function prevEntry(tbl, key)
  local keys = {}

  for k in pairs(tbl) do
    if not key or k < key then
      keys[#keys + 1] = k
    end
  end

  table.sort(keys)

  return keys[#keys], tbl[keys[#keys]]
end

--- Find the first sequence entry whose value equals to the given one, and
-- remove it.
-- @tparam table tbl the sequence
-- @param value the value
-- @return[1] the key of the removed entry
-- @return[1] the value of the removed entry
-- @treturn[2] nil no entry was found
local function removeFirst(tbl, value)
  for k, v in ipairs(tbl) do
    if v == value then
      table.remove(tbl, k)
      return k, v
    end
  end

  return nil
end

--- Find the first sequence entry that satisfies a predicate.
--
-- The predicate should return any value other than `nil` and `false` to stop
-- the iteration and return the current value.
--
-- The range of search is `[start; stop]`.
-- @tparam table tbl the sequence
-- @tparam function(element,key,tbl) predicate the predicate
-- @tparam[opt=1] int start the index to start searching from
-- @tparam[optchain=#tbl] int stop the index to stop searching at
-- @return[1] the entry key
-- @return[1] the entry value
-- @treturn[2] nil no entries satisfy the predicate
local function first(tbl, predicate, start, stop)
  for k = start or 1, stop or #tbl, 1 do
    local v = tbl[k]

    if v ~= nil and predicate(v, k, tbl) then
      return k, v
    end
  end

  return nil
end

--- Find the last sequence entry that satisfies a predicate.
--
-- The predicate should return any value other than `nil` and `false` to stop
-- the iteration and return the current value.
--
-- The range of search is `[start; stop]`.
-- @tparam table tbl the sequence
-- @tparam function(element,key,tbl) predicate the predicate
-- @tparam[opt=1] int start the start index
-- @tparam[optchain=#tbl] int stop the end index
-- @return[1] the entry key
-- @return[1] the entry value
-- @treturn[2] nil no entries satisfy the predicate
local function last(tbl, predicate, start, stop)
  for k = stop or #tbl, start or 1, -1 do
    local v = tbl[k]

    if v ~= nil and predicate(v, k, tbl) then
      return k, v
    end
  end

  return nil
end

--- @export
return {
  shalloweq = shalloweq,
  shallowcopy = shallowcopy,
  isin = isin,
  autoimport = autoimport,
  swapPairs = swapPairs,
  tableLen = tableLen,
  getKeys = getKeys,
  nextEntry = nextEntry,
  prevEntry = prevEntry,
  removeFirst = removeFirst,
  first = first,
  last = last,
}

