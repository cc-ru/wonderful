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

--- Default element attributes.
-- @module wonderful.element.attribute

local class = require("lua-objects")

local geometry = require("wonderful.geometry")
local tableUtil = require("wonderful.util.table")

local isin = tableUtil.isin
local shallowcopy = tableUtil.shallowcopy

--- The abstract atribute class.
local Attribute = class(
  nil,
  {name = "wonderful.element.attribute.Attribute"}
)

--- The base atribute class.
-- @type Attribute

--- The value of the attribute
-- @field Attribute.value

--- Construct a new attribute.
function Attribute:__new__(value)
  self.value = value
end

--- The on-set handler, called when the attribute is set.
-- @param element the element the attribute is assigned to.
-- @param[opt] previous the previous value, if any
function Attribute:onSet(element, previous)
end

--- The on-unset handler, called when the attribute is unset.
-- @param element the element the attribute was removed from.
-- @param[opt] new the new value, if any
function Attribute:onUnset(element, new)
end

---
-- @section end

--- The position attribute.
local Position = class(
  Attribute,
  {name = "wonderful.element.attribute.Position"}
)

--- The position attribute.
-- @type Position

--- The default value (`"static"`).
Position.DEFAULT = "static"

--- The possible options (`"static"`, `"absolute"`, `"relative"`, `"fixed"`).
Position.OPTIONS = {
  static = true,
  absolute = true,
  relative = true,
  fixed = true
}

--- Construct a new instance.
-- @tparam ?string value one of "static", "absolute", "relative", "fixed"
function Position:__new__(value)
  if self.OPTIONS[value] then
    self.value = value
  else
    self.value = self.DEFAULT
  end
end

--- Checks if the value is set to "static".
-- @treturn boolean
function Position:isStatic()
  return self.value == "static"
end

---
-- @section end

--- The margin attribute.
-- @see wonderful.geometry.Margin
local Margin = class(
  {Attribute, geometry.Margin},
  {name = "wonderful.element.attribute.Margin"}
)

--- The margin attribute.
-- @type Margin

--- Construct a new instance.
-- @tparam ?int l the left margin
-- @tparam ?int t the top margin
-- @tparam ?int r the right margin
-- @tparam ?int b the bottom margin
function Margin:__new__(...)
  self:superCall(geometry.Margin, "__new__", ...)
end

---
-- @section end

--- The padding attribute.
-- @see wonderful.geometry.Padding
local Padding = class(
  {Attribute, geometry.Padding},
  {name = "wonderful.element.attribute.Padding"}
)

--- The padding attribute.
-- @type Padding

--- Construct a new instance.
-- @tparam ?int l the left padding
-- @tparam ?int t the top padding
-- @tparam ?int r the right padding
-- @tparam ?int b the bottom padding
function Padding:__new__(...)
  self:superCall(geometry.Padding, "__new__", ...)
end

---
-- @section end

--- The focus attribute.
local Focus = class(Attribute, {name = "wonderful.element.attribute.Focus"})

--- The focus attribute.
-- @type Focus

--- Whether the element the attribute is applied to is permitted to get focus.
-- @field Focus.enabled

--- Construct a new instance.
-- @tparam[opt=true] boolean enable whether to enable focusing on an element
function Focus:__new__(enable)
  if enable == nil then
    self.enabled = true
  else
    self.enabled = enable
  end
end

--- @section end

--- The style class names.
local Classes = class(
  Attribute,
  {name = "wonderful.element.attribute.Classes"}
)

--- The style class names.
-- @type Classes

--- Construct a new instance.
-- @tparam string,... ... class names
function Classes:__new__(...)
  self.value = {}
  self.classes = {}

  local values = {...}

  for k, v in pairs(values) do
    self:add(v)
  end
end

--- Check if a class is set.
-- @tparam string value the class name
-- @treturn boolean
function Classes:isSet(value)
  return not not self.classes[value]
end

--- Add a class name to the attribute.
-- @tparam string value the class name
-- @treturn boolean `true` if the class name was added
function Classes:add(value)
  if type(value) == "string" and value ~= "" and not self.classes[value] then
    table.insert(self.value, value)
    self.classes[value] = true
    return true
  else
    return false
  end
end

--- Remove a class from the attribute.
-- @tparam string value the class name
-- @treturn boolean `true` is the class was removed
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

--- Toggle a class.
-- Removes the class if it's set, otherwise adds it.
-- @tparam string value the class name
-- @treturn boolean `true` if the class was toggled
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

---
-- @section end

--- The stretch attribute.
-- @see wonderful.layout.Layout
local Stretch = class(Attribute, {name = "wonderful.element.attribute.Stretch"})

--- The stretch attribute.
-- @type Stretch

--- The default value of the attribute (`0`).
Stretch.DEFAULT = 0

--- Construct a new instance.
-- @tparam ?number stretch a value
function Stretch:__new__(stretch)
  stretch = tonumber(stretch)

  if stretch and stretch >= 0 then
    self.value = stretch
  else
    self.value = self.DEFAULT
  end
end

---
-- @section end

--- The scroll box attribute.
-- @see wonderful.geometry.Box
local ScrollBox = class(
  {Attribute, geometry.Box},
  {name = "wonderful.element.attribute.ScrollBox"}
)

--- The scroll box attribute.
-- @type ScrollBox

--- Construct a new instance.
-- @tparam ?int x
-- @tparam ?int y
-- @tparam ?int w
-- @tparam ?int h
function ScrollBox:__new__(x, y, w, h)
  self:superCall(geometry.Box, "__new__", x, y, w, h)
end

function ScrollBox:onSet(element, previous)
  element:recompose()
end

function ScrollBox:onUnset(element, new)
  element:recompose()
end

---
-- @section end

---
-- @export
return {
  Attribute = Attribute,
  Position = Position,
  Margin = Margin,
  Padding = Padding,
  Focus = Focus,
  Classes = Classes,
  Stretch = Stretch,
  ScrollBox = ScrollBox,
}

