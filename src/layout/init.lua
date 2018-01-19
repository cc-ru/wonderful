local class = require("lua-objects")

local box = require("wonderful.layout.box")

local Layout = class(nil, {name = "wonderful.layout.Layout"})

function Layout:recompose(el)
  error("unimplemented abstract method Layout:recompose")
end

return {
  Layout = Layout,
  Direction = box.Direction,
  BoxLayout = box.BoxLayout,
  VBoxLayout = box.VBoxLayout,
  HBoxLayout = box.HBoxLayout
}

