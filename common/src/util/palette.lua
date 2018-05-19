--- GPU color palettes.
-- @module wonderful.util.palette

local funcUtil = require("wonderful.util.func")

--- Extract RGB channel values from a color.
-- @tparam int color a color
-- @treturn int a red channel value
-- @treturn int a green channel value
-- @treturn int a blue channel value
local function extract(color)
  color = color % 0x1000000
  local r = (color - color % 0x10000) / 0x10000
  local g = (color % 0x10000 - color % 0x100) / 0x100
  local b = color % 0x100

  return r, g, b
end

--- Calculate how much given colors differ visually.
-- @tparam int color1 the first color
-- @tparam int color2 the second color
local function delta(color1, color2)
  color1 = color1 % 0x1000000
  color2 = color2 % 0x1000000
  -- inlined: extract
  local r1 = (color1 - color1 % 0x10000) / 0x10000
  local g1 = (color1 % 0x10000 - color1 % 0x100) / 0x100
  local b1 = color1 % 0x100

  -- inlined: extract
  local r2 = (color2 - color2 % 0x10000) / 0x10000
  local g2 = (color2 % 0x10000 - color2 % 0x100) / 0x100
  local b2 = color2 % 0x100

  local dr = r1 - r2
  local dg = g1 - g2
  local db = b1 - b2

  return (0.2126 * dr^2 +
          0.7152 * dg^2 +
          0.0722 * db^2)
end

--- The T1 palette.
-- @type PaletteT1

--- Convert a color to a palette index.
-- @tparam PaletteT1 a palette
-- @tparam int a color
-- @treturn int the palette index
-- @function PaletteT1.deflate
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

--- Convert a palette index to a color.
-- @tparam PaletteT1 a palette
-- @tparam int an index
-- @treturn int the color
-- @function PaletteT1.inflate
local function t1inflate(palette, index)
  return palette[index + 1]
end

---
-- @section end

--- Construct a new T1 palette.
-- Such a palette contains two colors, one of which is black.
-- @tparam int secondColor the second color
-- @treturn PaletteT1 the palette
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

--- The T2 palette.
-- @type PaletteT2

--- Convert a color to a palette index.
-- @tparam PaletteT2 a palette
-- @tparam int a color
-- @treturn int the palette index
-- @function PaletteT2.deflate

--- Convert a palette index to a color.
-- @tparam PaletteT2 a palette
-- @tparam int an index
-- @treturn int the color
-- @function PaletteT2.inflate

local t2deflate = t1deflate
local t2inflate = t1inflate

---
-- @section end

--- Construct a new T2 palette.
-- Such a palette contains 16 fixed colors.
-- @treturn PaletteT2 the palette
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

--- The T3 palette.
-- @type PaletteT3

--- Convert a palette index to a color.
-- @tparam PaletteT3 a palette
-- @tparam int an index
-- @treturn int the color
-- @function PaletteT3.inflate

local t3inflate = t2inflate

local RCOEF = (6 - 1) / 0xFF
local GCOEF = (8 - 1) / 0xFF
local BCOEF = (5 - 1) / 0xFF

--- Convert a color to a palette index.
-- @tparam PaletteT3 a palette
-- @tparam int a color
-- @treturn int the palette index
-- @function PaletteT3.deflate
local t3deflate = function(palette, color)
  local paletteIndex = palette.t2deflate(palette, color)

  -- don't use `palette.len` here
  for i = 1, #palette, 1 do
    if palette[i] == color then
      return i - 1
    end
  end

  -- inlined: extract
  local r = (color - color % 0x10000) / 0x10000
  local g = (color % 0x10000 - color % 0x100) / 0x100
  local b = color % 0x100

  local idxR = r * RCOEF + 0.5
  idxR = idxR - idxR % 1

  local idxG = g * GCOEF + 0.5
  idxG = idxG - idxG % 1

  local idxB = b * BCOEF + 0.5
  idxB = idxB - idxB % 1

  local deflated = 16 + idxR * 40 + idxG * 5 + idxB
  local calcDelta = delta(t3inflate(palette, deflated % 0x100), color)
  local palDelta = delta(t3inflate(palette, paletteIndex % 0x100), color)

  if calcDelta < palDelta then
    return deflated
  else
    return paletteIndex
  end
end

---
-- @section end

--- Construct a new T3 palette.
-- Such a palette contains 16 variable and 240 fixed colors. The variable colors
-- are set to shades of grey by default.
-- @treturn PaletteT3 the palette
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

    local iG = (i / 5) % 8
    iG = iG - iG % 1

    local iR = (i / 5 / 8) % 6
    iR = iR - iR % 1

    local r = iR * 0xFF / (6 - 1) + 0.5
    r = r - r % 1

    local g = iG * 0xFF / (8 - 1) + 0.5
    g = g % 1

    local b = iB * 0xFF / (5 - 1) + 0.5
    b = b % 1

    palette[idx + 1] = r * 0x10000 + g * 0x100 + b
  end

  palette.deflate = funcUtil.cached1arg(t3deflate, 128, 2)
  palette.t2deflate = funcUtil.cached1arg(t2deflate, 128, 2)
  palette.inflate = t3inflate

  return palette
end

--- A pre-generated T1 palette (the second color is `0xffffff`).
local t1 = generateT1Palette(0xffffff)

--- A pre-generated T2 palette.
local t2 = generateT2Palette()

--- A pre-generated T3 palette with default palette colors.
local t3 = generateT3Palette()

---
-- @export
return {
  t1 = t1,
  t2 = t2,
  t3 = t3,

  extract = extract,
  delta = delta,

  generateT1Palette = generateT1Palette,
  generateT2Palette = generateT2Palette,
  generateT3Palette = generateT3Palette,
}

