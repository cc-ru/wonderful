local bit32 = require("bit32")
local component = require("component")
local computer = require("computer")

local class = require("lua-objects")

local Framebuffer = require("wonderful.buffer").Framebuffer
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

local DisplayManager = class(nil, {name = "wonderful.display.DisplayManager"})
local Display = class(nil, {name = "wonderful.display.Display"})

function DisplayManager:__new__()
  self.screens = {}
  self.gpus = {}
  self.inital = {}
  self.displays = {}

  self.maxDepth = 1

  local noScreens, noGPUs = true, true

  for address in component.list("screen", true) do
    self.screens[address] = {
      address = address,
      depth = tonumber(((computer.getDeviceInfo() or {})[address] or
                        {}).width) or 8,
      regions = {},
      preferredResolution = nil,
      forcedGPU = nil
    }

    noScreens = false
  end

  for address in component.list("gpu", true) do
    local maxDepth = tonumber(((computer.getDeviceInfo() or {})[address] or
                               {}).width) or 8

    self.gpus[address] = {
      address = address,
      depth = maxDepth
    }

    self.inital[address] = {
      screen = component.invoke(address, "getScreen"),
      depth = component.invoke(address, "getDepth") or maxDepth,
      background = component.invoke(address, "getBackground") or 0x000000,
      foreground = component.invoke(address, "getForeground") or 0xFFFFFF,
      resolution = {component.invoke(address, "getResolution")}
    }

    if not self.inital[address].resolution[1] then
      self.inital[address].resolution = {depthResolution(maxDepth)}
    end

    if maxDepth > self.maxDepth then
      self.maxDepth = maxDepth
    end

    noGPUs = false
  end

  if noScreens then
    error("no screens available")
  end

  if noGPUs then
    error("no GPUs available")
  end

  self.primaryScreen = component.getPrimary("screen")
  self.primaryGPU = component.getPrimary("gpu")
end

function DisplayManager:restore()
  for gpu, inital in pairs(self.inital) do
    local w, h = table.unpack(inital.resolution)

    if inital.screen then
      component.invoke(gpu, "bind", inital.screen)
    end

    component.invoke(gpu, "setDepth", inital.depth)
    component.invoke(gpu, "setBackground", inital.background)
    component.invoke(gpu, "setForeground", inital.foreground)
    component.invoke(gpu, "setResolution", w, h)
    component.invoke(gpu, "fill", 1, 1, w, h, " ")
  end

  require("term").clear()
end

function DisplayManager:setPreferredScreenResolution(address, w, h)
  self.screens[address].preferredResolution = {w, h}
end

function DisplayManager:forceScreenGPU(screen, gpu)
  self.screens[screen].forcedGPU = gpu
end

function DisplayManager:getScreenResolution(screen)
  local depth = self:getScreenDepth(screen)

  local dw, dh = depthResolution(depth)
  local w, h = table.unpack(self.screens[screen].preferredResolution or
                            {math.huge, math.huge})

  return math.min(w, dw), math.min(h, dh)
end

function DisplayManager:getScreenDepth(screen)
  local screen = self.screens[screen]

  return math.min(
    screen.depth,
    screen.forcedGPU and self.gpus[screen.forcedGPU].depth or self.maxDepth
  )
end

function DisplayManager:newDisplay(spec)
  local spec = spec or {}

  if spec.x and spec.y and spec.w and spec.h then
    spec.box = Box(spec.x, spec.y, spec.w, spec.h)
  end

  if not spec.screen then
    local candidates = {}

    for address, screen in pairs(self.screens) do
      local w, h = self:getScreenResolution(address)

      if spec.box and
          -- regions can overlap now
          -- not spec.box:intersectsOneOf(screen.regions) and
          spec.box.w + spec.box.x <= w and
          spec.box.h + spec.box.y <= h then
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

    if not candidates[1] then
      return
    end

    spec.screen = candidates[1].address
    spec.box = candidates[1].box
  end

  local display = Display(
    self, spec.screen, spec.box, self:getScreenDepth(spec.screen)
  )

  local w, h = self:getScreenResolution(spec.screen)
  local gpu = component.proxy(self:getGPU(display))
  gpu.setResolution(w, h)

  table.insert(self.displays, display)
  return display
end

function DisplayManager:getGPU(display)
  local candidates = {}
  local screen = self.screens[display.screen]

  for _, gpu in pairs(self.gpus) do
    if gpu.depth >= screen.depth then
      table.insert(candidates, gpu.address)
    end
  end

  table.sort(candidates, function(rhs, lhs)
    return self.gpus[rhs].depth < self.gpus[lhs].depth
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

--------------------------------------------------------------------------------

function Display:__new__(manager, screen, box, depth)
  self.manager = manager
  self.screen = screen
  self.box = box

  self.fb = Framebuffer {
    w = box.w,
    h = box.h,
    depth = depth
  }

  self.fb:optimize()
end

function Display:flush()
  local gpu = component.proxy(self.manager:getGPU(self))
  self.fb:flush(self.box.x, self.box.y, gpu)
end

return {
  DisplayManager = DisplayManager,
  Display = Display,
}

