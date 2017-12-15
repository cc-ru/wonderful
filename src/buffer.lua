local class = require("lua-objects")

local Buffer = class(nil, {name = "Buffer"})

function Buffer:__new__(args)
  self.w = args.w
  self.h = args.h
  self.depth = args.depth
end
