local class = require("lua-objects")

local Component = class(nil, {name = "wonderful.component.Component"})

function Component:__new__(x, y, w, h)
  self.parent = nil
  self:requestGeometry(x, y, w, h)
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

function Component:getStyle()
  local gui = self:getGUI()
  if gui then
    return gui.style
  else
    return nil
  end
end

function Component:requestGeometry(x, y, w, h)
  if self.parent then
    x, y, w, h = self.parent:compose(self, x, y, w, h)
  end
  self._x = x
  self._y = y
  self._w = w
  self._h = h
end

function Component.__getters:x()
  return self._x
end

function Component.__setters:x(x)
  self:requestGeometry(x, self._y, self._w, self._h)
end

function Component.__getters:y()
  return self._y
end

function Component.__setters:y(y)
  self:requestGeometry(self._x, y, self._w, self._h)
end

function Component.__getters:w()
  return self._w
end

function Component.__setters:w(w)
  self:requestGeometry(self._x, self._y, w, self._h)
end

function Component.__setters:h(h)
  self:requestGeometry(self._x, self._y, self._w, h)
end

function Component.__getters:h()
  return self._h
end

local Layout = class(
  Component,
  {name = "wonderful.component.Layout"}
)

function Layout:__new__(x, y, w ,h)
  self:superCall("__new__", x, y, w, h)
  self.children = {}
end

function Layout:addChild(child)
  -- TODO: events
  table.insert(self.children, child)
  child.parent = self

  -- TODO: redo in events
  local gui = self:getGUI()
  if gui then
    gui:updateLayers()
  end
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

function Layout:compose(component, x, y, w, h)
  return x, y, w, h
end

function Layout:requestGeometry(x, y, w, h)
  self:superCall("requestGeometry", x, y, w, h)
  -- Recompose
  for _, child in ipairs(self.children) do
    child:requestGeometry(child.x, child.y, child.w, child.h)
  end
end

return {
  Component = Component
}
