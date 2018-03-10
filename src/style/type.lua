local class = require("lua-objects")

local lexer = require("wonderful.style.lexer")

local ExprType = class(nil, {name = "wonderful.style.type.ExprType"})

function ExprType:parse(expr)
end

function ExprType:get()
  return self.value
end

local ColorType = class(ExprType, {name = "wonderful.style.type.ColorType"})

function ColorType:parse(expr)
  if #expr ~= 1 then
    error("Error parsing color: ColorToken expected")
  end

  if expr[1]:isa(ColorToken) then
    self.value = expr[1].value
  else
    error("Error parsing color: ColorToken expected")
  end
end

return {
  ExprType = ExprType,
}

