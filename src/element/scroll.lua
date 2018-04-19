local class = require("lua-objects")

local ScrollContext = class(
  nil,
  {name = "wonderful.element.stack.ScrollContext"}
)

function ScrollContext:__new__()
  self.fixed = {}
end
