local class = require("lua-objects")

local geometry = require("wonderful.geometry")
local tableUtil = require("wonderful.util.table")

local isin = tableUtil.isin
local shallowcopy = tableUtil.shallowcopy

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
Position.key = "position"

function Position:__new__(value)
  if self.OPTIONS[value] then
    self.value = value
  else
    self.value = self.DEFAULT
  end
end

function Position:isStatic()
  return self.value == "static"
end

local Margin = class(
  {Attribute, geometry.Margin},
  {name = "wonderful.element.attribute.Margin"}
)

Margin.key = "margin"

function Margin:__new__(...)
  self:superCall(geometry.Margin, "__new__", ...)
end

local Padding = class(
  {Attribute, geometry.Padding},
  {name = "wonderful.element.attribute.Padding"}
)

Padding.key = "padding"

function Padding:__new__(...)
  self:superCall(geometry.Padding, "__new__", ...)
end

local ZIndex = class(
  Attribute,
  {name = "wonderful.element.attribute.ZIndex"}
)

ZIndex.key = "zIndex"
ZIndex.DEFAULT = 1

function ZIndex:__new__(value)
  self.value = type(value) == "number" and value or ZIndex.DEFAULT
end

local Classes = class(
  Attribute,
  {name = "wonderful.element.attribute.Classes"}
)

Classes.key = "classes"

function Classes:__new__(...)
  self.value = {}
  self.classes = {}

  local values = {...}

  for k, v in pairs(values) do
    self:add(v)
  end
end

function Classes:isSet(value)
  return not not self.classes[value]
end

function Classes:add(value)
  if type(value) == "string" and value ~= "" and not self.classes[value] then
    table.insert(self.value, value)
    self.classes[value] = true
    return true
  else
    return false
  end
end

function Classes:remove(value)
  if type(value) == "string" and self.classes[value] then
    local _, k = isin(value, self.value)
    table.remove(self.value, k)
    self.classes[value] = nil
    return true
  else
    return false
  end
end

function Classes:toggle(value)
  if type(value) == "string" and value ~= "" then
    if self.classes[value] then
      return self:remove(value)
    else
      return self:add(value)
    end
  else
    return false
  end
end

local Stretch = class(Attribute, {name = "wonderful.element.attribute.Stretch"})

Stretch.key = "stretch"
Stretch.DEFAULT = 0

function Stretch:__new__(stretch)
  stretch = tonumber(stretch)

  if stretch and stretch >= 0 then
    self.value = stretch
  else
    self.value = self.DEFAULT
  end
end

local ScrollBox = class(
  {Attribute, geometry.Box},
  {name = "wonderful.element.attribute.ScrollBox"}
)

ScrollBox.key = "scrollBox"

function ScrollBox:__new__(x, y, w, h)
  self:superCall(geometry.Box, "__new__", x, y, w, h)
end

return {
  Attribute = Attribute,
  Position = Position,
  Margin = Margin,
  Padding = Padding,
  ZIndex = ZIndex,
  Classes = Classes,
  Stretch = Stretch,
  ScrollBox = ScrollBox,
}

