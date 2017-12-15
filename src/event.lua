local class = require("lua-objects")

local Event = class(nil, {name = "Event"})

function Event:__new__(renderer)
  self.renderer = renderer
end
