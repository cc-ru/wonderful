--- The default style properties.
-- @module wonderful.style.property

local class = require("lua-objects")

local wtype = require("wonderful.style.type")

local Property = class(nil, {name = "wonderful.style.property.Property"})

Property.name = "property"
Property.exprType = wtype.ExprType
Property.inherit = false

function Property:__new__(value)
  self.value = self.exprType:parse(value)
end

function Property:get()
  return self.value:get()
end

local Color = class(Property, {name = "wonderful.style.property.Color"})

Color.name = "color"
Color.exprType = wtype.ColorType
Color.inherit = true

local BgColor = class(Property, {name = "wonderful.style.property.BgColor"})

BgColor.name = "background-color"
BgColor.exprType = wtype.ColorType
BgColor.inherit = false

--- @export
return {
  Property = Property,

  Color = Color,
  BgColor = BgColor,
}

