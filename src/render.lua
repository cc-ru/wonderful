local component = require("component")
local computer = require("computer")

local class = require("lua-objects")

local wbuffer = require("wonderful.buffer")

local Box = require("wonderful.geometry").Box
local CellDiff = wbuffer.CellDiff

local function depthResolution(depth)
  if depth == 1 then
    return 50, 16
  elseif depth == 4 then
    return 80, 25
  else
    return 160, 50
  end
end

local function getFills(depth)
  if depth == 1 then
    return 16 - 6
  elseif depth == 4 then
    return 32 - 6
  elseif depth == 8 then
    return 64 - 6
  end
end

local function getArea(x0, y0, x1, y1)
  return (x1 - x0 + 1) * (y1 - y0 + 1)
end

local RenderTarget = class(nil, {name = "wonderful.render.RenderTarget"})

function RenderTarget:__new__(renderer, screen, box, depth)
  self.renderer = renderer
  self.screen = screen
  self.box = box
  self.fills = getFills(depth)

  local bufferArgs = {
    w = box.w,
    h = box.h,
    depth = depth
  }

  self.oldBuffer = wbuffer.Buffer(bufferArgs)
  self.newBuffer = wbuffer.Buffer(bufferArgs)
  self.diffBuffer = wbuffer.DiffBuffer(self.oldBuffer, self.newBuffer)
  self.palette = self.oldBuffer.palette
end

function RenderTarget:flush()
  local gpu = component.proxy(self.renderer:getGPU(self))

  self.diffBuffer:update()

  local colors = {}
  local x, y, chars, fg, bg, pos, index = 1, 1

  while true do
    if self.diffBuffer:get(x, y) ~= CellDiff.None then
      pos = x * 0x100 + y

      x, y, chars, fg, bg = self.diffBuffer:getLine(x, y)
      x = x + 1

      index = self.palette:deflate(fg) * 0x100 + self.palette:deflate(bg)

      if not colors[index] then
        colors[index] = {}
      end

      table.insert(colors[index], pos)
      table.insert(colors[index], chars)
    else
      x = x + 1
    end

    if x > self.diffBuffer.w then
      x = 1
      y = y + 1
    end

    if y > self.diffBuffer.h then
      break
    end
  end

  local calls = 0
  for index, lines in pairs(colors) do
    local fg = self.palette:inflate(bit32.rshift(index, 8))
    local bg = self.palette:inflate(bit32.band(index, 0xff))

    gpu.setForeground(fg)
    gpu.setBackground(bg)

    for i = 1, #lines, 2 do
      local pos = lines[i]
      local line = lines[i + 1]

      local x = bit32.rshift(pos, 8)
      local y = bit32.band(pos, 0xff)

      gpu.set(x, y, line)
    end

    calls = calls + 2 + math.floor(#lines / 2)
  end

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
      depth = ((computer.getDeviceInfo() or {})[address] or {}).width or 8,
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
      depth = ((computer.getDeviceInfo() or {})[address] or {}).width or 8
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

function Renderer:setPreferredScreenResolution(address, w, h)
  self.screens[address].preferredResolution = {w, h}
end

function Renderer:forceScreenGPU(screen, gpu)
  self.screens[screen].forcedGPU = gpu
end

function Renderer:getScreenResolution(screen)
  local depth = self:getScreenDepth(screen)

  local dw, dh = depthResolution(depth)
  local w, h = table.unpack(self.screens[screen].preferredResolution or
                            {math.huge, math.huge})

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

    spec.screen = candidates[1].address
    spec.box = candidates[1].box
  end

  local target = RenderTarget(
    self, spec.screen, spec.box, self:getScreenDepth(spec.screen)
  )

  local w, h = self:getScreenResolution(spec.screen)
  component.proxy(self:getGPU(target)).setResolution(w, h)

  table.insert(self.targets, target)
  return target
end

function Renderer:getGPU(target)
  local candidates = {}
  local screen = self.screens[target.screen]

  for _, gpu in pairs(self.gpus) do
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

