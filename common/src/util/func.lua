--- Various function utilities (eg cache).
-- @module wonderful.util.func

--- Decorate a function to cache results of execution.
-- When such a function is called, checks if the cache contains an entry for
-- such arguments. If it does, returns the entry. Otherwise, the original
-- function is called, and the result is stored in cache.
--
-- The original function must return the same result if called with the same
-- arguments.
--
-- The number of entries stored in cache can be limited.
--
-- @tparam function func a function to decorate
-- @tparam[opt=math.huge] int entries a cache size limit
-- @treturn function the decorated function
local function cached(func, entries)
  entries = entries or math.huge
  local cache = {}
  local count = 0
  return function(...)
    local args = table.pack(...)

    for k, v in pairs(cache) do
      local matches = true
      if args.n == k.n then
        for j = 1, k.n, 1 do
          if args[j] ~= k[j] then
            matches = false
            break
          end
        end
      else
        matches = false
      end
      if matches then
        return table.unpack(v)
      end
    end

    local out = table.pack(func(...))
    if count == entries then
      cache[next(cache)] = nil
    else
      count = count + 1
    end

    cache[args] = out
    return table.unpack(out)
  end
end

--- Decorate a function to cache results of execution.
-- Only a single argument is stored. Works considerably faster than
-- @{wonderful.util.func.cached} in such cases.
--
-- @tparam function func a function to decorate
-- @tparam[opt=math.huge] number entries a cache size limit
-- @tparam int pos an index of argument to cache
-- @treturn function the decorated function
-- @see wonderful.util.func.cached
local function cached1arg(func, entries, pos)
  entries = entries or math.huge
  local cache = {}
  local count = 0

  return function(...)
    local arg = select(pos, ...)
    if cache[arg] then
      return cache[arg]
    else
      if count == entries then
        cache[next(cache)] = nil
      else
        count = count + 1
      end
      local out = func(...)
      cache[arg] = out
      return out
    end
  end
end

---
-- @export
return {
  cached = cached,
  cached1arg = cached1arg,
}

