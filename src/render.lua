local com = require("component")

local class = require("lua-objects")

local event = require("wonderful.event")

local Bind = class(nil, {name = "wonderful.render.Bind"})

function Bind:__new__(args)
  -- TODO
end

local Renderer = class(nil, {name = "wonderful.render.Renderer"})

function Renderer:__new__(...)
  self.guis = {...}
  self.binds = {}
  self.eventEngine = event.Engine(self)

  for _, v in pairs(self.guis) do
    k.renderer = self
  end

  self:updateBinds()
end

function Renderer:updateBinds()
  -- TODO
end

return {
  Renderer = Renderer
}
