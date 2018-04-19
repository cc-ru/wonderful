-- Spawns a few rectangles, and sets the scroll box.
--
-- Uses: scrolling, styles, attributes, property references,
--       tree, layouts.

local com = require("component")
local event = require("event")

local wonderful = require("wonderful")
local wstyle = require("wonderful.style")
local welement = require("wonderful.element")
local wprop = require("wonderful.style.property")
local wattr = require("wonderful.element.attribute")

local class = require("lua-objects")

local wmain = wonderful.Wonderful()

local Rectangle = class(welement.Element, {name = "Rectangle"})

local doc = wmain:addDocument {style = [[
.root {
  background-color: #a0a0a0;
};

.child {
  background-color: #f0f0f0;
};
]]
}

local i = 0

function Rectangle:__new__(args)
  self:superCall("__new__", args)

  self.w = args.w
  self.h = args.h
  self.i = tostring(i)
  self.bg = self:propRef("background-color", wprop.BgColor({0xc3c3c3}))

  i = i + 1
end

function Rectangle:render(view)
  view:fill(1, 1, view.w, view.h, 0x000000, self.bg:get():get(), 1, " ")
  view:set(1, 1, 0x000000, self.bg:get():get(), 1, "Rect #" .. self.i)
  --view:set(2, 2, 0x000000, self.bg:get():get(), 1, self.i)
  view:set(1, 2, 0x000000, self.bg:get():get(), 1, tostring(self.calculatedBox))
  view:set(1, 3, 0x000000, self.bg:get():get(), 1, tostring(self.viewport))
  view:set(1, 4, 0x000000, self.bg:get():get(), 1, tostring(self:getLayoutBox()))
end

function Rectangle:sizeHint()
  return self.w, self.h
end

local rootRect = Rectangle {w = 80, h = 25}
rootRect:set(wattr.Classes("root"))
rootRect:set(wattr.ScrollBox(0, 3))
doc:appendChild(rootRect)

for i = 1, 25, 1 do
  local child = Rectangle {w = 60, h = 5}
  child:set(wattr.Classes("child"))
  child:set(wattr.Margin(0, 0, 0, 2))
  rootRect:appendChild(child)
end

-- print(doc.viewport)
-- print(rootRect.viewport)
-- do
--   local child = rootRect.childNodes[1]
--   print(child.calculatedBox, child.viewport)
-- end
-- do
--   local child = rootRect.childNodes[4]
--   print(child.calculatedBox, child.viewport)
-- end
--
-- os.exit()

wmain:render()

while true do
  local e = {event.pullMultiple("interrupted", "key_down")}

  if e[1] == "interrupted" then
    wmain:__destroy__()
    os.exit()
  elseif e[1] == "key_down" then
    local scrollBox = rootRect:get("scrollBox")

    if e[4] == 208 then -- arrow down
      rootRect:setScrollBox(scrollBox.x, scrollBox.y + 1, scrollBox.w, scrollBox.h)
      wmain:render()
    elseif e[4] == 200 then -- arrow up
      rootRect:setScrollBox(scrollBox.x, scrollBox.y - 1, scrollBox.w, scrollBox.h)
      wmain:render()
    end
  end
end

