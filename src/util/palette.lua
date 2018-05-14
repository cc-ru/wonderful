local funcUtil = require("wonderful.util.func")

local function extract(color)
  color = color % 0x1000000
  local r = (color - c % 0x10000) / 0x10000
  local g = (color % 0x10000 - color % 0x100) / 0x100
  local b = color % 0x100

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
  for idx = 1, palette.len, 1 do
    if palette[idx] == color then
      return idx - 1
    end
  end

  local idx, minDelta

  for i = 1, palette.len, 1 do
    local d = delta(palette[i], color)
    if not minDelta or d < minDelta then
      idx, minDelta = i, d
    end
  end

  return idx - 1
end

local function t1inflate(palette, index)
  return palette[index + 1]
end

local function generateT1Palette(secondColor)
  local palette = {
    0x000000,
    secondColor
  }

  palette.len = 2

  palette.deflate = funcUtil.cached1arg(t1deflate, 128, 2)
  palette.inflate = t1inflate

  return palette
end

local t2deflate = t1deflate
local t2inflate = t1inflate

local function generateT2Palette()
  local palette = {0xFFFFFF, 0xFFCC33, 0xCC66CC, 0x6699FF,
                   0xFFFF33, 0x33CC33, 0xFF6699, 0x333333,
                   0xCCCCCC, 0x336699, 0x9933CC, 0x333399,
                   0x663300, 0x336600, 0xFF3333, 0x000000}
  palette.len = 16

  palette.deflate = funcUtil.cached1arg(t2deflate, 128, 2)
  palette.inflate = t2inflate

  return palette
end

local t3inflate = t2inflate

local RCOEF = (6 - 1) / 0xFF
local GCOEF = (8 - 1) / 0xFF
local BCOEF = (5 - 1) / 0xFF

local t3deflate = function(palette, color)
  local paletteIndex = palette.t2deflate(palette, color)

  -- don't use `palette.len` here
  for i = 1, #palette, 1 do
    if palette[i] == color then
      return i - 1
    end
  end

  local r, g, b = extract(color)
  local idxR = math.floor(r * RCOEF + 0.5)
  local idxG = math.floor(g * GCOEF + 0.5)
  local idxB = math.floor(b * BCOEF + 0.5)
  local deflated = 16 + idxR * 40 + idxG * 5 + idxB
  local calcDelta = delta(t3inflate(palette, deflated % 0x100), color)
  local palDelta = delta(t3inflate(palette, paletteIndex % 0x100), color)

  if calcDelta < palDelta then
    return deflated
  else
    return paletteIndex
  end
end

local function generateT3Palette()
  local palette = {
    len = 16
  }

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

  palette.deflate = funcUtil.cached1arg(t3deflate, 128, 2)
  palette.t2deflate = funcUtil.cached1arg(t2deflate, 128, 2)
  palette.inflate = t3inflate

  return palette
end

return {
  t1 = generateT1Palette(),
  t2 = generateT2Palette(),
  t3 = generateT3Palette(),

  extract = extract,
  delta = delta,

  generateT1Palette = generateT1Palette,
  generateT2Palette = generateT2Palette,
  generateT3Palette = generateT3Palette,
}

