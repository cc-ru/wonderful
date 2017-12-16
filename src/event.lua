local class = require("lua-objects")

local Engine = class(nil, {name = "wonderful.event.Engine"})

function Engine:__new__(renderer)
  self.renderer = renderer
end

return {
  Engine = Engine
}
