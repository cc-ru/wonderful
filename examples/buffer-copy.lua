-- Tests Buffer:copyFrom method by performing self-to-self copy.
-- Press ^C to continue.

local event = require("event")

local wbuf = require("wonderful.buffer")

local gpu = require("component").gpu

local args = {w = 160, h = 50, depth = 8, debug = true}

local function wait()
  event.pull("interrupted")
end

local fb = wbuf.Framebuffer(args)
local lines = {"Self-copy test",
               "copied from se",
               "lf to self, uh"}
local w = #lines[1]
local h = #lines

local function drawBox(x, y)
  fb:fill(x, y, w, h, 0x000000, 0xffffff, 1, " ")
  fb:set(x, y, 0x000000, 0xffffff, 1, lines[1])
  fb:set(x, y + 1, 0x000000, 0xffffff, 1, lines[2])
  fb:set(x, y + 2, 0x000000, 0xffffff, 1, lines[3])
end

local x0 = math.floor(args.w / 2 - w / 2)
local y0 = math.floor(args.h / 2 - h / 2)
drawBox(x0, y0)

fb:flush(1, 1, gpu)

wait()

local cw = 2 * w - 4
local ch = 2 * h - 2

local x1 = math.floor(args.w / 6 - cw / 2)
local x2 = math.floor(args.w / 2 - w / 2)
local x3 = math.floor(args.w / 6 * 5 - cw / 2)

local y1 = math.floor(args.h / 6 - ch / 2)
local y2 = math.floor(args.h / 2 - h / 2)
local y3 = math.floor(args.h / 6 * 5 - ch / 2)

-- top-left
drawBox(x1 + w - 4, y1 + h - 2)

-- top
drawBox(x2, y1 + h - 2)

-- top-right
drawBox(x3, y1 + h - 2)

-- right
drawBox(x3, y2)

-- bottom-right
drawBox(x3, y3)

-- bottom
drawBox(x2, y3)

-- bottom-left
drawBox(x1 + w - 4, y3)

-- left
drawBox(x1 + w - 4, y2)

fb:flush(1, 1, gpu)

wait()

fb:copyFrom(fb, x1 + w - 4, y1 + h - 2, w, h, x1, y1)
fb:copyFrom(fb, x2, y1 + h - 2, w, h, x2, y1)
fb:copyFrom(fb, x3, y1 + h - 2, w, h, x3 + w - 4, y1)
fb:copyFrom(fb, x3, y2, w, h, x3 + w - 4, y2)
fb:copyFrom(fb, x3, y3, w, h, x3 + w - 4, y3 + h - 2)
fb:copyFrom(fb, x2, y3, w, h, x2, y3 + h - 2)
fb:copyFrom(fb, x1 + w - 4, y3, w, h, x1, y3 + h - 2)
fb:copyFrom(fb, x1 + w - 4, y2, w, h, x1, y2)

fb:flush(1, 1, gpu)

wait()
