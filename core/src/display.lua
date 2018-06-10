-- Copyright 2018 the wonderful GUI project authors
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

--- Display manager and GPU pool.
-- @module wonderful.display

local bit32 = require("bit32")
local component = require("component")
local computer = require("computer")

local class = require("lua-objects")

local Framebuffer = require("wonderful.buffer").Framebuffer
local Box = require("wonderful.geometry").Box

--- Deduce a maximum resolution by a maximum depth.
-- @tparam int depth the depth
-- @treturn int a width
-- @treturn int a height
local function depthResolution(depth)
  if depth == 1 then
    return 50, 16
  elseif depth == 4 then
    return 80, 25
  else
    return 160, 50
  end
end

--- A class that manages GPU pool and stores displays.
local DisplayManager = class(nil, {name = "wonderful.display.DisplayManager"})

--- A display class.
-- A display is a reference to an area on a screen.
local Display = class(nil, {name = "wonderful.display.Display"})

--- A class that manages GPU poll and stores displays.
-- @type DisplayManager

--- Construct a new display manager instance.
function DisplayManager:__new__()
  self.screens = {}
  self.gpus = {}
  self.inital = {}
  self.displays = {}

  self.maxDepth = 1

  local deviceInfo = computer.getDeviceInfo() or {}

  local noScreens, noGPUs = true, true

  for address in component.list("screen", true) do
    self.screens[address] = {
      address = address,
      depth = tonumber((deviceInfo[address] or
                        {}).width) or 8,
      regions = {},
      preferredResolution = nil,
      forcedGPU = nil
    }

    noScreens = false
  end

  for address in component.list("gpu", true) do
    local maxDepth = tonumber((deviceInfo[address] or
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

--- Restores the previous state of GPUs.
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

--- Set a preferred resolution for a screen.
-- @tparam string address the address of the screen
-- @tparam int w the width
-- @tparam int h the height
function DisplayManager:setPreferredScreenResolution(address, w, h)
  self.screens[address].preferredResolution = {w, h}
end

--- Forcefully bind a GPU to a screen.
-- @tparam string screen the screen address
-- @tparam string gpu the GPU address
function DisplayManager:forceScreenGPU(screen, gpu)
  self.screens[screen].forcedGPU = gpu
end

--- Choose a resolution of a screen.
-- @tparam string screen the screen address
-- @treturn int the width
-- @treturn int the height
function DisplayManager:getScreenResolution(screen)
  local depth = self:getScreenDepth(screen)

  local dw, dh = depthResolution(depth)
  local w, h = table.unpack(self.screens[screen].preferredResolution or
                            {math.huge, math.huge})

  return math.min(w, dw), math.min(h, dh)
end

--- Get a depth of a screen.
-- @tparam string screen the screen address
-- @treturn int the depth
function DisplayManager:getScreenDepth(screen)
  local screen = self.screens[screen]

  return math.min(
    screen.depth,
    screen.forcedGPU and self.gpus[screen.forcedGPU].depth or self.maxDepth
  )
end

--- Create a new display by its specification.
-- The debug mode introduces a few checks that catch errors and bugs where it
-- makes sense. It may slow down the program significantly, though.
-- @tparam table spec the specification
-- @tparam[opt] int spec.x a top-left cell's column number
-- @tparam[opt] int spec.y a top-left cell's row number
-- @tparam[opt] int spec.w a width of the display
-- @tparam[opt] int spec.h a height of the display
-- @tparam[opt] string spec.screen a screen address
-- @tparam[opt] boolean spec.debug whether the debug mode should be set
-- @treturn wonderful.display.Display the display
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
    self, spec.screen, spec.box, self:getScreenDepth(spec.screen), self.debug
  )

  if not self.debug then
    display:optimize()
  end

  local w, h = self:getScreenResolution(spec.screen)
  local gpu = component.proxy(self:getGPU(display))
  gpu.setResolution(w, h)

  table.insert(self.displays, display)
  return display
end

--- Get a GPU for a display
-- @tparam wonderful.display.Display display the display
-- @treturn string a GPU address
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

---
-- @section end

--------------------------------------------------------------------------------

--- A display class.
-- A display is a reference to an area on a screen.
-- @type Display

--- Construct a new display.
-- You **should not** use this directly.
-- @see wonderful.display.DisplayManager
function Display:__new__(manager, screen, box, depth, debug)
  self.manager = manager
  self.screen = screen
  self.box = box

  self.fb = Framebuffer {
    w = box.w,
    h = box.h,
    depth = depth,
    debug = debug
  }

  self.fb:optimize()
end

--- Flush a display's framebuffer onto the display's screen.
function Display:flush()
  local gpu = component.proxy(self.manager:getGPU(self))
  self.fb:flush(self.box.x, self.box.y, gpu)
end

---
-- @export
return {
  DisplayManager = DisplayManager,
  Display = Display,
}

