local com = require("component")
local comp = require("computer")

local class = require("lua-objects")

local component = require("wonderful.component")
local compose = require("wonderful.compose")
local style = require("wonderful.style")
local wbuffer = require("wonderful.buffer")

local GUI = class(component.Component, {name = "wonderful.gui.GUI"})

function GUI:__new__(args)
  self:superCall('__new__')
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

  self.buffer = wbuffer.Buffer {
    w = args.w or gpu.getWidth(),
    h = args.h or gpu.getHeight(),
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

  self.composer = compose.Composer(self)
end

return {
  GUI = GUI
}
