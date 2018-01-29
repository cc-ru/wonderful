local bit32 = require("bit32")

local util = {}

function util.shallowcopy(orig)
  if type(orig) ~= "table" then
    return orig
  end

  local copy = {}
  print(copy)

  for k, v in pairs(orig) do
    copy[k] = v
  end

  return copy
end

function util.shalloweq(lhs, rhs)
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

function util.isin(value, tbl)
  for k, v in pairs(tbl) do
    if v == value then
      return true, k
    end
  end
  return false
end

util.iter = {}
do
  function util.iter.wrap(iter, state, var)
    return {
      iter = iter,
      state = state,
      var = var
    }
  end

  function util.iter.ipairsSorted(t, rev)
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

  function util.iter.ipairsRev(table)
    local i = #table

    return function()
      if table[i] then
        i = i - 1
        return i + 1, table[i + 1]
      end
    end
  end

  function util.iter.chain(...)
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
end

util.palette = {}
do
  local function extract(color)
    color = color % 0x1000000
    local r = math.floor(color / 0x10000)
    local g = math.floor((color - r * 0x10000) / 0x100)
    local b = color - r * 0x10000 - g * 0x100
    return r, g, b
  end

  local function delta(color1, color2)
    local r1, g1, b1 = extract(color1)
    local r2, g2, b2 = extract(color2)
    local dr = r1 - r2
    local dg = g1 - g2
    local db = b1 - b2
    return (0.2126 * dr^2 +
            0.7152 * dg^2 +
            0.0722 * db^2)
  end

  local function t1deflate(palette, color)
    for idx, v in pairs(palette) do
      if v == color then
        return idx - 1
      end
    end

    local deltas = {}
    for idx, v in pairs(palette) do
      table.insert(deltas, {idx, delta(v, color)})
    end

    table.sort(deltas, function(a, b)
      return a[2] < b[2]
    end)

    return deltas[1][1] - 1
  end

  local function t1inflate(palette, index)
    return palette[index + 1]
  end

  local function generateT1Palette(secondColor)
    local palette = {
      0x000000,
      secondColor
    }

    return setmetatable(palette, {__index={
      deflate = t1deflate,
      inflate = t1inflate
    }})
  end

  util.palette.t1 = generateT1Palette()

  local t2deflate = t1deflate
  local t2inflate = t1inflate

  local function generateT2Palette()
    local palette = {0xFFFFFF, 0xFFCC33, 0xCC66CC, 0x6699FF,
                     0xFFFF33, 0x33CC33, 0xFF6699, 0x333333,
                     0xCCCCCC, 0x336699, 0x9933CC, 0x333399,
                     0x663300, 0x336600, 0xFF3333, 0x000000}

    return setmetatable(palette, {__index={
      deflate = t2deflate,
      inflate = t2inflate
    }})
  end

  util.palette.t2 = generateT2Palette()

  local t3inflate = t2inflate

  local function t3deflate(palette, color)
    local paletteIndex = t2deflate(palette, color)
    for k, v in pairs(palette) do
      if v == color then
        return paletteIndex
      end
    end

    local r, g, b = extract(color)
    local idxR = math.floor(r * (6 - 1) / 0xFF + 0.5)
    local idxG = math.floor(g * (8 - 1) / 0xFF + 0.5)
    local idxB = math.floor(b * (5 - 1) / 0xFF + 0.5)
    local deflated = 16 + idxR * 8 * 5 + idxG * 5 + idxB
    if (delta(t3inflate(palette, deflated % 0x100), color) <
        delta(t3inflate(palette, bit32.band(paletteIndex, 0x100)), color)) then
      return deflated
    else
      return paletteIndex
    end
  end

  local function generateT3Palette()
    local palette = {}

    for i = 1, 16, 1 do
      palette[i] = 0xFF * i / (16 + 1) * 0x10101
    end

    for idx = 16, 255, 1 do
      local i = idx - 16
      local iB = i % 5
      local iG = math.floor(i / 5) % 8
      local iR = math.floor(i / 5 / 8) % 6
      local r = math.floor(iR * 0xFF / (6 - 1) + 0.5)
      local g = math.floor(iG * 0xFF / (8 - 1) + 0.5)
      local b = math.floor(iB * 0xFF / (5 - 1) + 0.5)
      palette[idx + 1] = r * 0x10000 + g * 0x100 + b
    end

    return setmetatable(palette, {__index={
      deflate = t3deflate,
      inflate = t3inflate
    }})
  end

  util.palette.t3 = generateT3Palette()
end

return util

