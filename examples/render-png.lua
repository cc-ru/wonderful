-- Draws a 160×100 PNG image.
--
-- Requires a T3 display setup and the libPNGimage library, which you can
-- install using the following command:
--
--   hpm install libpngimage

local path = require("shell").resolve((...))

local png = require("libPNGimage")
local wbuffer = require("wonderful.buffer")

local fb = wbuffer.Framebuffer {w = 160, h = 50, depth = 8, debug = false}
fb:optimize()

local img = png.newFromFile(path)

print("Setting...")

os.sleep(0)

for y = 1, 50, 1 do
  for x = 1, 160, 1 do
    local ru, gu, bu = img:getPixel(x - 1, 2 * y - 2)
    local rb, gb, bb = img:getPixel(x - 1, 2 * y - 1)
    fb:set(x, y,
           (ru * 0x10000 +
            gu * 0x100 +
            bu),
           (rb * 0x10000 +
            gb * 0x100 +
            bb), 1, "▀")
  end

  os.sleep(0)
end

print("Rendering...")

os.sleep(0)

fb:flush(1, 1, require("component").gpu)

require("event").pull("interrupted")
