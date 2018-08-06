local event = require("event")
local kbd = require("keyboard")

local wonderful = require("wonderful")

local class = require("lua-objects")

local Classes = wonderful.element.attribute.Classes
local Margin = wonderful.element.attribute.Margin
local ScrollBox = wonderful.element.attribute.ScrollBox

local wmain = wonderful.Wonderful {
  debug = false
}

local Rectangle = class(wonderful.element.Element, {name = "Rectangle"})

local doc = wmain:addDocument {style = [[
.root {
  background-color: #808080;
};

.level-1 {
  background-color: #c0c0c0;
};

.level-2 {
  background-color: #fff;
};
]]
}

local i = 0

function Rectangle:__new__(args)
  self:superCall("__new__", args)

  self.w = args.w
  self.h = args.h
  self.i = tostring(i)
  self.bg = self:propRef("background-color",
                         wonderful.style.property.BgColor({0xc3c3c3}))

  i = i + 1
end

function Rectangle:render(view)
  view:fill(1, 1, view.w, view.h, 0x000000, self.bg:get():get(), 1, " ")
  view:set(1, 1, 0x000000, self.bg:get():get(), 1,
           "Rect #" .. self.i)
  view:set(1, 2, 0x000000, self.bg:get():get(), 1,
           "calc " .. tostring(self.calculatedBox))
  view:set(1, 3, 0x000000, self.bg:get():get(), 1,
           "view " .. tostring(self.viewport))
  view:set(1, 4, 0x000000, self.bg:get():get(), 1,
           "lyot " .. tostring(self:getLayoutBox()))
  view:set(1, 5, 0x000000, self.bg:get():get(), 1,
           "cord " .. tostring(view.coordBox))
  view:set(1, 6, 0x000000, self.bg:get():get(), 1,
           "vbox " .. tostring(view.box))
  view:set(1, 7, 0x000000, self.bg:get():get(), 1,
           "lybx " .. tostring(self.parentNode:getLayoutBox()))
end

function Rectangle:sizeHint()
  return self.w, self.h
end

local rootRect = Rectangle {w = 80, h = 25}
rootRect:set(Classes("root"))
rootRect:set(ScrollBox(0, 0))
doc:appendChild(rootRect)

local level1 = Rectangle {w = 76, h = 15}
level1:set(Classes("level-1"))
level1:set(Margin(2, 4, 0, 0))
level1:set(ScrollBox(0, 0))
rootRect:appendChild(level1)

for _ = 1, 10, 1 do
  local level2 = Rectangle {w = 72, h = 7}
  level2:set(Classes("level-2"))
  level2:set(Margin(2, 4, 0, 0))
  level1:appendChild(level2)
end

wmain:render()

while true do
  local e = {event.pullMultiple("interrupted", "key_down")}

  if e[1] == "interrupted" then
    wmain:__destroy__()
    os.exit()
  elseif e[1] == "key_down" then
    local element = rootRect

    if kbd.isShiftDown() then
      element = level1
    end

    local scrollBox = element:get(ScrollBox)

    if e[4] == 208 then -- arrow down
      element:set(ScrollBox(scrollBox.x, scrollBox.y + 1,
                            scrollBox.w, scrollBox.h))
      wmain:render()
    elseif e[4] == 200 then -- arrow up
      element:set(ScrollBox(scrollBox.x, scrollBox.y - 1,
                            scrollBox.w, scrollBox.h))
      wmain:render()
    end
  end
end

