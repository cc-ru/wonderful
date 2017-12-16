-- Various mixins for Components

local class = require("lua-objects")

local function chooseValue(hardcoded, property, default)
  if property and property.important then
    return property.value
  elseif hardcoded then
    return hardcoded
  elseif property then
    return property.value
  else
    return default
  end
end

local Position = class(nil, {name = "wonderful.style.mixin.Position"})

function Position:getX()
  local prop = self.style:getProperty("x")
  return chooseValue(self.x, prop, 1)
end

function Position:getY()
  local prop = self.style:getProperty("y")
  return chooseValue(self.y, prop, 1)
end

local Dimensions = class(nil, {name = "wonderful.style.mixin.Dimensions"})

function Dimensions:getWidth()
  local prop = self.style:getProperty("width")
  return chooseValue(self.w, prop)
end

function Dimensions:getHeight()
  local prop = self.style:getProperty("height")
  return chooseValue(self.h, prop)
end
