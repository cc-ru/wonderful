local smix = require("wonderful.style.mixin")

local class = require("lua-objects")

local Component = class(
  smix.Position,
  {name = "wonderful.component.Component"}
)

function Component:__new__()
  self.x = nil
  self.y = nil
  self.id = nil
  self.class = nil
  self.parent = nil
  self.children = {}
  self.style = nil
end

function Component:render(view, buffer)
end

function Component:getProperty(name)
  return self.style:get(self, name)
end

return {
  Component = Component
}
