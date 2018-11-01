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

--- The main module, which exports the Wonderful class.
-- You need an instance of this class in order to run a GUI. It allows you to
-- create documents (which you're not supposed to create any other way
-- unless you're casting some pitch-black magic).
--
-- It's also responsible for catching events (such as touches or key presses)
-- when running the event loop.
-- @module wonderful

local component = require("component")
local event = require("event")

local class = require("lua-objects")

local geometry = require("wonderful.geometry")
local signal = require("wonderful.std.event.signal")
local tableUtil = require("wonderful.util.table")
local iterUtil = require("wonderful.util.iter")

local DisplayManager = require("wonderful.display").DisplayManager
local Document = require("wonderful.element.document").Document
local Widget = require("wonderful.widget").Widget
local ipairsRev = iterUtil.ipairsRev

--- The main class of the library.
-- @cl Wonderful
local Wonderful = class(nil, {name = "wonderful.Wonderful"})

--- @type Wonderful

--- Construct a new instance.
--
-- The debug mode introduces a few checks that allow to catch bugs and errors.
-- It may slow down the program significantly, though.
--
-- @tparam[opt] table args a keyword arguments table
-- @tparam[opt] boolean args.debug whether the debug mode should be set
function Wonderful:__new__(args)
  if args then
    if args.debug == nil then
      self._debug = true
    else
      self._debug = not not args.debug
    end
  end

  self._displayManager = DisplayManager()

  if not self._debug then
    self._displayManager:optimize()
  end

  self._documents = {}
  self._signals = {}
  self._running = false
  self:updateKeyboards()

  self:addSignal("touch", signal.Touch)
  self:addSignal("drag", signal.Drag)
  self:addSignal("drop", signal.Drop)
  self:addSignal("scroll", signal.Scroll)

  self:addSignal("key_down", signal.KeyDown)
  self:addSignal("key_up", signal.KeyUp)
  self:addSignal("clipboard", signal.Clipboard)

  self:addSignal("interrupted", signal.Interrupt)

  if not self._debug then
    self:optimize()
  end
end

function Wonderful:isRunning()
  return self._running
end

--- Update the keyboard bind mappings.
function Wonderful:updateKeyboards()
  self._keyboards = {}

  for screen in component.list("screen", true) do
    for _, keyboard in ipairs(component.invoke(screen, "getKeyboards")) do
      self._keyboards[keyboard] = screen
    end
  end
end

--- Create a new instance of @{wonderful.element.document.Document}.
-- @tparam table args a keyword argument table
-- @tparam[opt] int args.x a column number of the document region's top-left cell
-- @tparam[opt] int args.y a row number of the document region's top-left cell
-- @tparam[opt] int args.w a width of the document region
-- @tparam[opt] int args.h a height of the document region
-- @tparam[opt] string args.screen a screen address
-- @treturn wonderful.element.document.Document the document instance
-- @see wonderful.element.document.Document:__new__
function Wonderful:addDocument(args)
  args = args or {}

  if args.x and args.y and args.w and args.h then
    args.box = geometry.Box(args.x, args.y, args.w, args.h)

    if not self._debug then
      args.box:optimize()
    end
  end

  local display = self._displayManager:newDisplay {
    box = args.box,
    screen = args.screen,
    debug = self._debug
  }

  if not self._debug then
    display:optimize()
  end

  local document = Document {display = display}

  if not self._debug then
    document:optimize()
  end

  table.insert(self._documents, document)
  return document
end

--- Render the documents.
function Wonderful:render(noFlush, force)
  for _, document in ipairs(self._documents) do
    local buffer = document:getDisplay():getFramebuffer()

    local walker = force and document.nlrWalk or document.flagWalk

    walker(document, function(widget)
      if widget:isa(Widget) and widget:getBoundingBox() then
        local coordBox = widget:getBoundingBox()
        local viewport = widget:getViewport()

        local view = buffer:view(coordBox:getX(), coordBox:getY(),
                                 coordBox:getWidth(), coordBox:getHeight(),
                                 viewport:unpack())

        if force then
          widget:requestRender(true)
        end

        widget:flush(view)
      end
    end, "_shouldRender")
  end

  if not noFlush then
    for _, display in ipairs(self._displayManager:getDisplays()) do
      display:flush()
    end
  end
end

--- Compose all documents.
function Wonderful:compose()
  for _, document in ipairs(self._documents) do
    document:flagWalk(function(element)
      element:commitComposition()
    end, "_shouldCompose")
  end
end

--- Trace a "hit": find an element by touch coordinates.
-- @tparam string screen a screen address
-- @tparam number x a column number
-- @tparam number y a row number
-- @return an element
function Wonderful:hit(screen, x, y)
  local hit

  for _, document in ipairs(self._documents) do
    if document:getDisplay():getScreen() == screen and
       document:getDisplay():getBox():has(x, y) then

      document:nlrWalk(function(element)
        if element:getCalculatedBox():has(x, y) then
          hit = element
        end
      end)
    end
  end

  return hit
end

--- Add a new signal to dispatch.
-- @tparam string name a signal name
-- @param cls a @{wonderful.std.event.signal.Signal} class
function Wonderful:addSignal(name, cls)
  self._signals[name] = cls
end

--- Run the event loop.
function Wonderful:run(inThread)
  local success, traceback = xpcall(function()
    self._running = true

    self:recomposeAll()
    self:render()

    while self._running do
      local pulled = {event.pull()}
      local name = table.remove(pulled, 1)

      if name and self._signals[name] then
        local inst = self._signals[name](table.unpack(pulled))

        if signal.SCREEN_SIGNALS[name] then
          local hit = self:hit(inst:getScreen(), inst:getX(), inst:getY())

          if hit then
            hit:dispatchEvent(inst)
          end
        elseif signal.KEYBOARD_SIGNALS[name] then
          local screen = self._keyboards[inst:getKeyboard()]

          if screen then
            for _, document in ipairs(self._documents) do
              if document:getDisplay():getScreen() == screen then
                document:dispatchEvent(inst, true)
              end
            end
          end
        else
          for _, document in ipairs(self._documents) do
            document:dispatchEvent(inst, true)
          end
        end

        self:recomposeAll()
        self:render()
      end
    end
  end, function(msg)
    if type(msg) == "table" and msg.reason then
      -- `os.exit()` raises table errors
      msg = msg.reason
    end

    return debug.traceback(msg)
  end)

  self:__destroy__()

  if not success then
    local message = ("Wonderful event loop crashed while running. Error:\n" ..
                     traceback)

    if inThread then
      -- threads don't print errors to screen
      io.stderr:write(message .. "\n")
    end

    error(message, 2)
  end
end

--- Create an event loop thread, and start the loop.
--
-- Requires the `thread` library, available in OpenOS 1.6.4 and higher.
--
-- @return the thread handle
function Wonderful:runThreaded()
  local thread = require("thread")

  return thread.create(self.run, self, true)
end

--- Stop the event loop.
function Wonderful:stop()
  self._running = false
  event.push("[" .. tostring(self) .. "] stop")
end

--- Destroy an instance of the main class.
-- Runs @{wonderful.display.DisplayManager:restore}, and cleans up.
function Wonderful:__destroy__()
  self._running = false
  self._displayManager:restore()
  self._displayManager:clearDisplays()
  self._documents = {}
end

--- @export
local module = {
  Wonderful = Wonderful,
}

return tableUtil.autoimport(module, "wonderful")

