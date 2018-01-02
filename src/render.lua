local com = require("component")

local class = require("lua-objects")

local event = require("wonderful.event")
local wbuffer = require("wonderful.buffer")

local Bind = class(nil, {name = "wonderful.render.Bind"})

function Bind:__new__(gui)
  self.gpu = com.proxy(gui.gpuAddr)
  self.screen = com.proxy(gui.screenAddr)
  self.gui = gui
  self.buffer = wbuffer.Buffer {
    w = gui.w,
    h = gui.h,
    depth = gui.buffer.depth
  }
end

function Bind:__eq(other)
  return self.gpu.address == other.gpu.address and
         self.screen.address == other.screen.address
end

local Renderer = class(nil, {name = "wonderful.render.Renderer"})

function Renderer:__new__()
  self.guis = {}
  self.binds = {}
  self.eventEngine = event.Engine(self)
end

function Renderer:add(gui)
  local bind = Bind(gui)
  for _, v in pairs(self.binds) do
    if v == bind then
      error("this bind is already used")
    end
  end
  table.insert(self.guis, gui)
  table.insert(self.binds, bind)
  gui.renderer = self
end

return {
  Renderer = Renderer
}
