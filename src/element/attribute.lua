local class = require("lua-objects")

local geometry = require("wonderful.geometry")

local Attribute = class(
  nil,
  {name = "wonderful.element.attribute.Attribute"}
)

function Attribute:__new__(key, value)
  self.key = key
  self.value = value
end

local Position = class(
  Attribute,
  {name = "wonderful.element.attribute.Position"}
)

Position.DEFAULT = "static"
Position.OPTIONS = {
  static = true,
  absolute = true,
  relative = true,
  fixed = true
}

function Position:__new__(value)
  self.key = "position"

  if Position.OPTIONS[value] then
    self.value = value
  else
    self.value = Position.DEFAULT
  end
end

function Position:isStatic()
  return self.value == "static"
end

local Margin = class(
  {Attribute, geometry.Margin},
  {name = "wonderful.element.attribute.Margin"}
)

function Margin:__new__(...)
  self.key = "margin"
  self:superCall(geometry.Margin, "__new__", ...)
end

local Padding = class(
  {Attribute, geometry.Padding},
  {name = "wonderful.element.attribute.Padding"}
)

function Padding:__new__(...)
  self.key = "padding"
  self:superCall(geometry.Padding, "__new__", ...)
end

local ZIndex = class(
  Attribute,
  {name = "wonderful.element.attribute.ZIndex"}
)

ZIndex.DEFAULT = 1

function ZIndex:__new__(value)
  self.key = "zIndex"
  self.value = type(value) == "number" and value or ZIndex.DEFAULT
end

return {
  Attribute = Attribute,
  Position = Position,
  Margin = Margin,
  Padding = Padding,
  ZIndex = ZIndex
}

