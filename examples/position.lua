--- A demo of different `wonderful.element.attribute.Position` values.

local event = require("event")
local kbd = require("keyboard")
local thread = require("thread")

local class = require("lua-objects")
local wonderful = require("wonderful")

local wmain = wonderful.Wonderful {debug = false}

local doc = wmain:addDocument()

local Rectangle = class(wonderful.element.Element, {name = "Rectangle"})

function Rectangle:__new__(args)
  self:superCall("__new__", args)

  self.w = args.w
  self.h = args.h
  self.name = args.name
  self.bg = args.bg
  self.alpha = args.alpha or 1
end

function Rectangle:_render(view)
  view:fill(1, 1, view:getWidth(), view:getHeight(),
            self.bg, self.bg, self.alpha, nil)
  view:set(2, 2, 0x000000, nil, 1, self.name)
  view:set(2, 3, 0x000000, nil, 1, tostring(self:getCalculatedBox()))
end

function Rectangle:sizeHint()
  return self.w, self.h
end

function Rectangle:__tostring__()
  return ("Rectangle {w = %d, h = %d, name = %q}"):format(
    self.w,
    self.h,
    self.name
  )
end

local root = Rectangle {w = 160,
                        h = 50,
                        bg = 0x808080,
                        name = "root",
                        scrollBox = {0, 0}}

doc:appendChild(root)

for i = 1, 5, 1 do
  local c = Rectangle {w = 146,
                       h = 15,
                       bg = 0xc2c2c2,
                       name = "container #" .. i,
                       margin = {2, 1, 0, 0},

  -- Here, we declare the positioning as relative. This makes
  -- the following attribute, which is ignored if the position is
  -- set to static, specify the offset relative to the usual
  -- position computed by the layout.
                       position = "relative",
                       boundingBox = {i - 1}}

  root:appendChild(c)

  for j = 1, 5, 1 do
    c:appendChild(
      Rectangle {w = 142,
                 h = 7,
                 bg = 0xffffff,
                 name = "child #" .. i .. "." .. j,
                 margin = {2, 1, 0, 0}}
    )
  end
end

root:appendChild(
  Rectangle {w = 156,
             h = 7,
             bg = 0xa5a5a5,
             name = "absolute element",
             alpha = 0.5,

  -- This pops it out of the element flow: its position isn't
  -- calculated by the layout. The position is still relative to
  -- the scroll box, though: it scrolls as if it was a part of
  -- the element flow.
             position = "absolute",

  -- Arguments: left offset, top offset, width, height.
  --
  -- Here, the height isn't specified: the value will therefore be taken
  -- from `Rectangle:sizeHint()`
             boundingBox = {4, 6, 125}}
)

root:appendChild(
  Rectangle {w = 156,
             h = 7,
             bg = 0xa5a5a5,
             name = "fixed element",
             alpha = 0.5,

  -- Fixed positioning is similar to absolute, but it is relative to
  -- the parent's calculated box. In other words, it doesn't scroll
  -- at all.
             position = "fixed",
             boundingBox = {3, 10, 125}}
)

local function shiftByY(element, dy)
  local sb = element.scrollBox

  sb:setY((sb:getY() or 0) + dy)
end

root:addListener {
  event = wonderful.std.event.signal.KeyDown,
  handler = function(self, e, handler)
    if e:getCode() == kbd.keys.left or e:getCode() == kbd.keys.right then
      local signum = 1

      if e:getCode() == kbd.keys.left then
        signum = -1
      end

      -- Only update the first five children of `root`.
      for i = 1, 5, 1 do
        local c = root:getChildren()[i]
        c.boundingBox:setLeft(c.boundingBox:getLeft() + (i - 1) * signum)
      end
    elseif e:getCode() == kbd.keys.up or e:getCode() == kbd.keys.down then
      local dy = 1

      if e:getCode() == kbd.keys.up then
        dy = -1
      end

      -- Only update the first five children of `root`.
      for i = 1, 5, 1 do
        shiftByY(root:getChildren()[i], dy)
      end

      shiftByY(root, dy)
    end
  end,
}

thread.create(function()
  repeat until event.pull("interrupted")

  wmain:stop()
end)

wmain:run()

os.exit()
