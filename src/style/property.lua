local class = require("lua-objects")

local wtype = require("wonderful.style.type").ExprType

local Property = class(nil, {name = "wonderful.style.property.Property"})

Property.exprType = wtype.ExprType

function Property:__new__(value)
  self.value = wtype.ExprType()
end

function Property:get()
  return self.value:get()
end

return {
  Property = Property,
}

