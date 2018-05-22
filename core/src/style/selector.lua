--- The default style selectors.
-- @module wonderful.style.selector

local class = require("lua-objects")

local Selector = class(nil, {name = "wonderful.style.selector.Selector"})

function Selector:__new__(value)
  self.value = value
end

function Selector:matches(component)
  return true
end

--- @export
return {
  Selector = Selector,
}

