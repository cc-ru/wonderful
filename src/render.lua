local com = require("component")

local class = require("lua-objects")

local event = require("wonderful.event")

local Bind = class(nil, {name = "Bind"})

function Bind:__new__(args)
  -- TODO
end

local Renderer = class(nil, {name = "Renderer"})

function Renderer:__new__(...)
  self.guis = {...}
  self.binds = {}
  self.eventEngine = event.Engine(self)

  self:updateBinds()
end

function Renderer:updateBinds()
  -- TODO
end
