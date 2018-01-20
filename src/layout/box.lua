local class = require("lua-objects")

local Layout = require("wonderful.layout").Layout

local Direction = {
  TopToBottom = 0,
  BottomToTop = 1,
  LeftToRight = 2,
  RightToLeft = 3
}

local BoxLayout = class(Layout, {name = "wonderful.layout.box.BoxLayout"})

function BoxLayout:__new__(direction)
  self.direction = direction
end

function BoxLayout:recompose(el)
  -- TODO
end

local VBoxLayout = class(BoxLayout, {name = "wonderful.layout.box.VBoxLayout"})

function VBoxLayout:__new__(reversed)
  self:superCall(BoxLayout, "__new__",
      reversed and Direction.BottomToTop or Direction.TopToBottom)
end

local HBoxLayout = class(BoxLayout, {name = "wonderful.layout.box.HBoxLayout"})

function HBoxLayout:__new__(reversed)
  self:superCall(BoxLayout, "__new__",
      reversed and Direction.RightToLeft or Direction.LeftToRight)
end

return {
  Direction = Direction,
  BoxLayout = BoxLayout,
  VBoxLayout = VBoxLayout,
  HBoxLayout = HBoxLayout
}

