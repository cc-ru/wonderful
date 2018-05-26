-- Copyright 2018 the wonderful GUI project authors
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

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

