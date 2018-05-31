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

--- Swaps the keys and values of a table.
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

---
-- @export
return {
  shalloweq = shalloweq,
  shallowcopy = shallowcopy,
  isin = isin,
  autoimport = autoimport,
  swapPairs = swapPairs,
}

