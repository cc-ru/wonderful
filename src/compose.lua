local class = require("lua-objects")

local Layout = require("wonderful.component").Layout

local Composer = class(nil, {name = "wonderful.compose.Composer"})

function Composer:__new__(gui)
  self.gui = gui
  self.composition = setmetatable({}, {__mode = "k"})
  self:register(gui)
end

function Composer:register(component, x, y, w, h)
  self.composition[component] = {}
  self:requestGeometry(component, x, y, w, h)
  self:updateLayers()
end

function Composer:requestGeometry(component, x, y, w, h)
  local data = self:getComposition(component)
  if component.parent then
    x, y, w, h = component.parent:compose(component, x, y, w, h)
  end
  data.x = x
  data.y = y
  data.w = w
  data.h = h
  return x, y, w, h
end

function Composer:getComposition(component)
  return self.composition[component]
end

function Composer:unregister(component)
  self.composition[component] = nil
  self:updateLayers()
end

function Composer:updateLayers()
  local layer = 1
  local popupLayer = -1
  local function update(component, popup)
    for _, v in ipairs(component.children) do
      if v.popup or popup then
        self:getComposition(v).layer = popupLayer
        popupLayer = popupLayer - 1
      else
        self:getComposition(v).layer = layer
        layer = layer + 1
      end
    end
    for _, v in ipairs(component.children) do
      if v:isa(Layout) then
        update(v, v.popup or popup)
      end
    end
  end
  self:getComposition(self.gui).layer = layer
  layer = layer + 1
  update(self.gui, false)
  -- Make pop-ups float above all non-popup elements.
  for k, v in self.composition do
    if v.layer < 0 then
      v.layer = layer - v.layer - 1
    end
  end
end

return {
  Composer = Composer
}
