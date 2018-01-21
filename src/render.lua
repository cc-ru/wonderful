local computer = require("computer")
local component = require("component")

local class = require("lua-objects")

local wbuffer = require("wonderful.buffer")
local Box = require("wonderful.geometry").Box

local function depthResolution(depth)
  if depth == 1 then
    return 50, 16
  elseif depth == 4 then
    return 80, 25
  else
    return 160, 50
  end
end

local RenderTarget = class(nil, {name = "wonderful.render.RenderTarget"})

function RenderTarget:__new__(renderer, screen, box, depth)
  self.renderer = renderer
  self.screen = screen
  self.box = box

  local bufferArgs = {
    w = box.w,
    h = box.h,
    depth = depth
  }

  self.oldBuffer = wbuffer.Buffer(bufferArgs)
  self.newBuffer = wbuffer.Buffer(bufferArgs)
end

function RenderTarget:flush()
  local gpu = component.proxy(self.renderer:getGPU(self))

  -- TODO: Render here

  local tmp = self.oldBuffer
  self.oldBuffer = self.newBuffer
  self.newBuffer = tmp
end

local Renderer = class(nil, {name = "wonderful.render.Renderer"})

function Renderer:__new__()
  self.screens = {}
  self.gpus = {}
  self.targets = {}

  self.maxDepth = 1

  local noScreens, noGPUs = true, true

  for address in component.list("screen", true) do
    self.screens[address] = {
      proxy = component.proxy(address),
      address = address,
      depth = ((computer.getDeviceInfo() or {})[address] or {}).width or 3,
      regions = {},
      preferredResolution = nil,
      forcedGPU = nil
    }

    noScreens = false
  end

  for address in component.list("gpu", true) do
    self.gpus[address] = {
      proxy = component.proxy(address),
      address = address,
      depth = ((computer.getDeviceInfo() or {})[address] or {}).width or 3
    }

    local curDepth = component.invoke(address, "maxDepth")
    if curDepth > self.maxDepth then
      self.maxDepth = curDepth
    end

    noGPUs = false
  end

  if noScreens then
    error("who stole the screen?")
  end

  if noGPUs then
    error("who stole the GPU?")
  end

  self.primaryScreen = component.getPrimary("screen")
  self.primaryGPU = component.getPrimary("gpu")
end

function Renderer:setPreferredScreenResolution(screen, w, h)
  self.screens[address].preferredResolution = {w, h}
end

function Renderer:forceScreenGPU(screen, gpu)
  self.screens[screen].forcedGPU = gpu
end

function Renderer:getScreenResolution(screen)
  local depth = self:getScreenDepth(screen)

  local dw, dh = depthResolution(depth)
  local w, h = table.unpack(screen.preferredResolution
      or {math.huge, math.huge})

  return math.min(w, dw), math.min(h, dh)
end

function Renderer:getScreenDepth(screen)
  local screen = self.screens[screen]

  return math.min(
    screen.depth,
    screen.forcedGPU and self.gpus[screen.forcedGPU].depth or self.maxDepth
  )
end

function Renderer:newTarget(spec)
  local spec = spec or {}

  if spec.x and spec.y and spec.w and spec.h then
    spec.box = Box(spec.x, spec.y, spec.w, spec.h)
  end

  if not spec.screen then
    local candidates = {}

    for address, screen in pairs(self.screens) do
      local w, h = self:getScreenResolution(address)

      if spec.box
         and not spec.box:intersectsOneOf(screen.regions)
         and spec.box.w + spec.box.x <= w
         and spec.box.h + spec.box.y <= h then
        screen.box = spec.box
        table.insert(candidates, 1, screen)
      elseif #screen.regions == 0 then
        screen.box = Box(1, 1, w, h)
        table.insert(candidates, 1, screen)
      end
    end

    table.sort(candidates, function(rhs, lhs)
      return rhs.depth > lhs.depth
    end)

    local primaryIndex
    for i, screen in ipairs(candidates) do
      if self.primaryScreen == screen.address then
        primaryIndex = i
        break
      end
    end

    if primaryIndex then
      local primary = table.remove(candidates, primaryIndex)
      table.insert(candidates, 1, primary)
    end

    spec.screen = candidates[1]
    spec.box = candidates[1].box
  end

  return RenderTarget(self, spec.screen, spec.box, getScreenDepth(spec.screen))
end

function Renderer:getGPU(target)
  local candidates = {}
  local screen = self.screens[target.screen]

  for _, gpu in ipairs(self.gpus) do
    if gpu.depth >= screen.depth then
      table.insert(candidates, gpu.address)
    end
  end

  table.sort(candidates, function(rhs, lhs)
    return rhs.depth < lhs.depth
  end)

  local bindIndex
  for i, gpu in ipairs(candidates) do
    if component.invoke(gpu, "getScreen") == screen.address then
      bindIndex = i
    end
  end

  if bindIndex then
    local bind = table.remove(candidates, bindIndex)
    table.insert(candidates, 1, bind)
  else
    component.invoke(candidates[1], "bind", screen.address, false)
  end

  return candidates[1]
end

return {
  Renderer = Renderer,
  RenderTarget = RenderTarget
}

