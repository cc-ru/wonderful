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

--- The default style types.
-- @module wonderful.style.type

local class = require("lua-objects")

local lexer = require("wonderful.style.lexer")

local ExprType = class(nil, {name = "wonderful.style.type.ExprType"})

function ExprType:__new__(value)
  self.value = value
end

function ExprType:parse(expr)
end

function ExprType:get()
  return self.value
end

local ColorType = class(ExprType, {name = "wonderful.style.type.ColorType"})

function ColorType:parse(expr)
  if #expr ~= 1 then
    error("Color expected")
  end

  if type(expr[1]) == "number" then
    return ColorType(expr[1])
  else
    error("Color expected")
  end
end

--- @export
return {
  ExprType = ExprType,

  ColorType = ColorType,
}

