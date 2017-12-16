local class = require("lua-objects")

local Composer = class(nil, {name = "wonderful.compose.Composer"})

function Composer:__new__(gui)
  self.gui = gui
end

return {
  Composer = Composer
}
