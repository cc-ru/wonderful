local class = require("lua-objects")

local Box = class(nil, {name = "wonderful.geometry.Box"})

function Box:__new__(x, y, w, h)
  self.x = x
  self.y = y
  self.w = w
  self.h = h
end

return {
  Box = Box
}

