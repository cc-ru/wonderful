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

local function cached1arg(func, entries, pos)
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

return {
  cached = cached,
  cached1arg = cached1arg,
}
