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
  return (x1 - x0) * (y1 - y0)
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
end

function RenderTarget:flush()
  -- TODO: group by color
  local gpu = component.proxy(self.renderer:getGPU(self))

  self.diffBuffer:update()

  local fills = self.fills

  for x = 1, self.diffBuffer.w, 1 do
    for y = 1, self.diffBuffer.h, 1 do
      local diff = self.diffBuffer:get(x, y)
      if diff ~= CellDiff.None then
        local figs = {{0, self.diffBuffer:getLine(x, y, false)},
                      {0, self.diffBuffer:getLine(x, y, true)}}
        if fills > 0 then
          figs[3] = {0, self.diffBuffer:getRect(x, y, false)}
          figs[4] = {0, self.diffBuffer:getRect(x, y, true)}
        end

        for i = 1, #figs, 1 do
          figs[i][1] = getArea(x, y, figs[i][2], figs[i][3])
        end

        local lineMaxIdx = figs[2][1] > figs[1][1] and 2 or 1
        local lineMax = figs[lineMaxIdx][1]

        local selected

        if fills > 0 then
          local rectMaxIdx = figs[4][1] > figs[3][1] and 4 or 3
          local rectMax = figs[rectMaxIdx][1]

          -- Fills are twice as expensive
          if rectMax > lineMax * 2 then
            selected = rectMaxIdx
          end
        end

        if not selected then
          selected = lineMaxIdx
        end

        local fg, bg = figs[selected][5], figs[selected][6]

        if gpu.getForeground() ~= fg then
          gpu.setForeground(fg)
        end
        if gpu.getBackground() ~= bg then
          gpu.setBackground(bg)
        end

        local w, h = figs[selected][2] - x + 1, figs[selected][3] - y + 1
        if selected == 1 then
          gpu.set(x, y, figs[1][4])
        elseif selected == 2 then
          gpu.set(x, y, figs[2][4], true)
        elseif selected == 3 or selected == 4 then
          gpu.fill(x, y, w, h, figs[selected][4])
          fills = fills - 1
        end

        self.diffBuffer:fill(x, y, w, h, CellDiff.None)
      end
    end
  end

  self.oldBuffer:copyFrom(self.newBuffer)
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
  local w, h = table.unpack(screen.preferredResolution or
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
          not spec.box:intersectsOneOf(screen.regions) and
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

