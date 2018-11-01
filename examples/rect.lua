-- Spawns a few rectangles, which may change every time
-- they're rendered, and renders them 10 times.
--
-- Uses: tree, property references

local wonderful = require("wonderful")

local class = require("lua-objects")

local wmain = wonderful.Wonderful {
  debug = false
}

local Rectangle = class(wonderful.widget.Widget, {name = "Rectangle"})

local doc = wmain:addDocument {}

local i = 1

function Rectangle:__new__(args)
  wonderful.widget.Widget.__new__(self, args)

  self.i = i

  i = i + 1
end

function Rectangle:_render(view)
  view:fill(1, 1, view:getWidth(), view:getHeight(),
            0xffffff, 0x000000, 1,
            math.random() > 0.5 and "#" or "X")
end

function Rectangle:sizeHint()
  return 80, 1
end

local box = wonderful.layout.box.BoxLayout()
doc:insertChild(box)

for _ = 1, 25 do
  box:appendChild(Rectangle())
end

for _ = 1, 10 do
  doc:requestRender()
  wmain:render()
  os.sleep(0.05)
end

