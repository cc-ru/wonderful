local class = require("lua-objects")

local Composer = class(nil, {name = "Composer"})

function Composer:__new__(gui)
  self.gui = gui
end
