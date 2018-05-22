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

