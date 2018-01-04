local com = require("component")
local comp = require("computer")

local class = require("lua-objects")

local component = require("wonderful.component")
local style = require("wonderful.style")
local wbuffer = require("wonderful.buffer")

local GUI = class(component.Layout, {name = "wonderful.gui.GUI"})

function GUI:__new__(args)
  if args.gpu and com.type(args.gpu) == "gpu" then
    self.gpuAddr = args.gpu
  else
    self.gpuAddr = com.gpu.address
  end
  local gpu = com.proxy(self.gpuAddr)

  self.kbdAddr = args.kbd or args.keyboard
  local deviceInfo = comp.getDeviceInfo()
  if not (self.kbdAddr and deviceInfo[self.kbdAddr] and
          deviceInfo[self.kbdAddr].description == "Keyboard") then
    for addr, info in pairs(deviceInfo) do
      if info.description == "Keyboard" then
        self.kbdAddr = addr
        break
      end
    end
  end

  if args.screen and com.type(args.screen) == "screen" then
    self.screenAddr = args.screen
  else
    self.screenAddr = gpu.getScreen()
  end

  local w = args.w or gpu.getResolution()
  local h = args.h or select(2, gpu.getResolution())

  self.layers = {}

  self:superCall("__new__", 1, 1, w, h)

  self.buffer = wbuffer.Buffer {
    w = w,
    h = h,
    depth = args.depth or gpu.getDepth()
  }

  if args.style and args.style:isa(style.Style) then
    self.style = args.style
  elseif type(args.style) == "table" and args.style.read then
    self.style = style.Style.fromBuffer(args.style)
  elseif type(args.style) == "string" then
    self.style = style.Style.fromString(args.style)
  end

  self.style:setGUI(self)
end

-- redefine wonderful.component:Component's method to end the call chain here
function GUI:getGUI()
  return self
end

function GUI:updateLayers()
  self.layers = {}
  local layer = 1
  local popupLayer = -1

  local function update(component, popup)
    for _, child in ipairs(component.children) do
      if child.popup or popup then
        self.layers[popupLayer] = child
        popupLayer = popupLayer - 1
      else
        self.layers[layer] = child
        layer = layer + 1
      end
    end
    for _, child in ipairs(component.children) do
      if child:isa(Layout) then
        update(child, child.popup or popup)
      end
    end
  end

  self.layers[layer] = self
  layer = layer + 1
  update(self, false)

  -- Make pop-ups float above all non-popup elements.
  for i = -1, popupLayer + 1, -1 do
    self.layers[layer - i - 1] = self.layers[i]
    self.layers[i] = nil
  end
end

return {
  GUI = GUI
}
