-- Spawns a few rectangles, which may change every time
-- they're rendered, and renders them 10 times.
--
-- Uses: styles, tree, property references

local com = require("component")

local wonderful = require("wonderful")
local wstyle = require("wonderful.style")

local class = require("lua-objects")

local wmain = wonderful.Wonderful {
  debug = false
}

local Rectangle = class(wonderful.element.LeafElement, {name = "Rectangle"})

local doc = wmain:addDocument {style = wstyle.WonderfulStyle {
  types = {
    Rect = Rectangle
  },
  string = [[
@Rect {
  color: #eee;
};
]]
}}

local i = 1

function Rectangle:__new__(args)
  self:superCall("__new__", args)

  self.color = self:propRef("color")
  self.i = i

  i = i + 1
end

function Rectangle:render(view)
  view:fill(1, 1, view.w, view.h, self.color:get():get(), 0x000000, 1,
            math.random() > 0.5 and "#" or "X")
end

function Rectangle:sizeHint()
  return 80, 1
end

local Dummy = class(wonderful.element.Element, {name = "Dummy"})

function Dummy:sizeHint()
  return 80, 25
end

local dummy = Dummy()

doc:appendChild(dummy)

for i = 1, 25 do
  dummy:appendChild(Rectangle())
end

for i = 1, 10 do
  wmain:render()
  os.sleep(0.05)
end
