--- A demo of different `wonderful.element.attribute.Position` values.

local event = require("event")
local kbd = require("keyboard")
local thread = require("thread")

local class = require("lua-objects")
local wonderful = require("wonderful")

local BoundingBox = wonderful.element.attribute.BoundingBox
local Margin = wonderful.element.attribute.Margin
local Position = wonderful.element.attribute.Position
local ScrollBox = wonderful.element.attribute.ScrollBox

local wmain = wonderful.Wonderful {debug = false}

local doc = wmain:addDocument()

local Rectangle = class(wonderful.element.Element, {name = "Rectangle"})

function Rectangle:__new__(w, h, bg, name, alpha)
  self:superCall("__new__")

  self.w = w
  self.h = h
  self.name = name
  self.bg = bg
  self.alpha = alpha or 1
end

function Rectangle:render(view)
  view:fill(1, 1, view.w, view.h, self.bg, self.bg, self.alpha, nil)
  view:set(2, 2, 0x000000, nil, 1, self.name)
  view:set(2, 3, 0x000000, nil, 1, tostring(self.calculatedBox))
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

local root = Rectangle(160, 50, 0x808080, "root")
  :set(ScrollBox(0, 0))

doc:appendChild(root)

for i = 1, 5, 1 do
  local c = Rectangle(146, 15, 0xc2c2c2, "container #" .. i)
    :set(Margin(2, 1, 0, 0))
    -- Here, we declare the positioning as relative. This makes
    -- the following attribute, which is ignored if the position is
    -- unset or set to static, specify the offset relative to the usual
    -- position, computed by the layout.
    :set(Position("relative"))
    :set(BoundingBox(i - 1))

  root:appendChild(c)

  for j = 1, 5, 1 do
    c:appendChild(
      Rectangle(142, 7, 0xffffff, "child #" .. i .. "." .. j)
        :set(Margin(2, 1, 0, 0))
    )
  end
end

root:appendChild(
  Rectangle(156, 7, 0xa5a5a5, "absolute element", 0.5)
    -- This pops it out of the element flow: its position isn't
    -- calculated by the layout. The position is still relative to
    -- the scroll box, though: it scrolls as if it was a part of
    -- the element flow.
    :set(Position("absolute"))
    -- Arguments: left offset, top offset, width, height.
    --
    -- Here, the height isn't specified: the value will therefore be taken
    -- from `Rectangle:sizeHint()`
    :set(BoundingBox(4, 6, 125))
)

root:appendChild(
  Rectangle(156, 7, 0xa5a5a5, "fixed element", 0.5)
    -- Fixed positioning is similar to absolute, but it is relative to
    -- the parent's calculated box. In other words, it doesn't scroll
    -- at all.
    :set(Position("fixed"))
    :set(BoundingBox(3, 10, 125))
)

local function shiftByY(element, dy)
  local sb = element:get(ScrollBox, true)
  element:set(ScrollBox(sb.x or 0, (sb.y or 0) + dy, sb.w, sb.h))
end

root:addListener {
  event = wonderful.signal.KeyDown,
  handler = function(self, e, handler)
    if e.code == kbd.keys.left or e.code == kbd.keys.right then
      local signum = 1

      if e.code == kbd.keys.left then
        signum = -1
      end

      -- Only update the first five children of `root`.
      for i = 1, 5, 1 do
        local c = root.childNodes[i]
        c:set(BoundingBox(c:get(BoundingBox).left + (i - 1) * signum))
      end
    elseif e.code == kbd.keys.up or e.code == kbd.keys.down then
      local dy = 1

      if e.code == kbd.keys.up then
        dy = -1
      end

      -- Only update the first five children of `root`.
      for i = 1, 5, 1 do
        shiftByY(root.childNodes[i], dy)
      end

      shiftByY(root, dy)
    end
  end,
}

local exitedWithError = false

thread.waitForAll({
  wmain:runThreaded(),
  thread.create(function()
    repeat until event.pull("interrupted")

    wmain:stop()
  end)
})

os.exit()
