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

local function isin(value, tbl)
  for k, v in pairs(tbl) do
    if v == value then
      return true, k
    end
  end
  return false
end

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

return {
  shalloweq = shalloweq,
  shallowcopy = shallowcopy,
  isin = isin,
  autoimport = autoimport,
}

