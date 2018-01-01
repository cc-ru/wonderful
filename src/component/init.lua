local smix = require("wonderful.style.mixin")

local class = require("lua-objects")

local Component = class(
  smix.Position,
  {name = "wonderful.component.Component"}
)

function Component:__new__()
  self.styleClass = nil
  self.parent = nil
  self.style = nil
end

function Component:render(view)
end

function Component:getProperty(name)
  return self.style:get(self, name)
end

function Component:getGUI()
  if self.parent then
    return self.parent:getGUI()
  else
    return nil
  end
end

function Component:getRenderer()
  local gui = self:getGUI()
  if gui then
    return gui.renderer
  else
    return nil
  end
end

function Component:getEvtEngine()
  local renderer = self:getRenderer()
  if renderer then
    return renderer.eventEngine
  else
    return nil
  end
end

local Layout = class(
  Component,
  {name = "wonderful.component.Layout"}
)

function Layout:__new__()
  self:superCall("__new__")
  self.children = {}
end

function Layout:addChild(child)
  -- TODO: events
  table.insert(self.children, child)
  child.parent = self
end

function Layout:removeChild(child)
  -- TODO: events
  for i = 1, #self.children, 1 do
    if self.children[i] == child then
      table.remove(self.children, i)
      child.parent = nil
      return true
    end
  end
  return false
end

return {
  Component = Component
}
