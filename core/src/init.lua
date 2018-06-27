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

local document = require("wonderful.element.document")
local display = require("wonderful.display")
local geometry = require("wonderful.geometry")
local signal = require("wonderful.signal")
local tableUtil = require("wonderful.util.table")

--- The main class of the library.
local Wonderful = class(nil, {name = "wonderful.Wonderful"})

--- The main class of the library.
-- @type Wonderful

--- Whether the event loop is running.
-- @field Wonderful.running

--- Construct a new instance.
-- The debug mode introduces a few checks that allow to catch bugs and errors.
-- It may slow down the program significantly, though.
-- @tparam[opt] table args a keyword arguments table
-- @tparam[opt] boolean args.debug whether the debug mode should be set
function Wonderful:__new__(args)
  if args then
    if args.debug == nil then
      self.debug = true
    else
      self.debug = not not args.debug
    end
  end

  self.displayManager = display.DisplayManager()

  if not self.debug then
    self.displayManager:optimize()
  end

  self.documents = {}
  self.signals = {}
  self.running = false
  self:updateKeyboards()

  self:addSignal("touch", signal.Touch)
  self:addSignal("drag", signal.Drag)
  self:addSignal("drop", signal.Drop)
  self:addSignal("scroll", signal.Scroll)

  self:addSignal("key_down", signal.KeyDown)
  self:addSignal("key_up", signal.KeyUp)
  self:addSignal("clipboard", signal.Clipboard)

  self:addSignal("interrupted", signal.Interrupt)

  if not self.debug then
    self:optimize()
  end
end

--- Update the keyboard bind mappings.
function Wonderful:updateKeyboards()
  self.keyboards = {}

  for screen in component.list("screen", true) do
    for _, keyboard in ipairs(component.invoke(screen, "getKeyboards")) do
      self.keyboards[keyboard] = screen
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
-- @tparam[opt] wonderful.style.Style|wonderful.style.buffer.Buffer|{["read"]=function,...}|string args.style a value to pass to the @{wonderful.element.document.Document|Document}'s constructor as a style
-- @treturn wonderful.element.document.Document the document instance
-- @see wonderful.element.document.Document:__new__
function Wonderful:addDocument(args)
  local args = args or {}

  if args.x and args.y and args.w and args.h then
    args.box = geometry.Box(args.x, args.y, args.w, args.h)

    if not self.debug then
      args.box:optimize()
    end
  end

  local display = self.displayManager:newDisplay {
    box = args.box,
    screen = args.screen,
    debug = self.debug
  }

  if not self.debug then
    display:optimize()
  end

  local document = document.Document {
    style = args.style,
    display = display
  }

  if not self.debug then
    document:optimize()
  end

  table.insert(self.documents, document)
  return document
end

function Wonderful:render()
  for _, document in ipairs(self.documents) do
    local buf = document.display.fb

    document:nlrWalk(function(el)
      if el.calculatedBox then
        local coordBox = el.calculatedBox
        local viewport = el.viewport

        local view = buf:view(coordBox.x,
                              coordBox.y,
                              coordBox.w,
                              coordBox.h,
                              viewport.x,
                              viewport.y,
                              viewport.w,
                              viewport.h)

        el:render(view)
      end
    end)
  end

  for _, display in ipairs(self.displayManager.displays) do
    display:flush()
  end
end

--- Trace a "hit": find an element by touch coordinates.
-- @tparam string screen a screen address
-- @tparam number x a column number
-- @tparam number y a row number
-- @return an element
function Wonderful:hit(screen, x, y)
  local hit

  for _, document in ipairs(self.documents) do
    if document.display.screen == screen and
       document.display.box:has(x, y) then

      document:nlrWalk(function(element)
        if element.calculatedBox:has(x, y) then
          hit = element
        end
      end)
    end
  end

  return hit
end

--- Add a new signal to dispatch.
-- @tparam string name a signal name
-- @param cls a @{wonderful.signal.Signal} class
function Wonderful:addSignal(name, cls)
  self.signals[name] = cls
end

--- Run the event loop.
function Wonderful:run()
  local success, traceback = xpcall(function()
    self.running = true

    self:render()

    while self.running do
      local pulled = {event.pull()}
      local name = table.remove(pulled, 1)

      if name and self.signals[name] then
        local inst = self.signals[name](table.unpack(pulled))

        if signal.SCREEN_SIGNALS[name] then
          local hit = self:hit(inst.screen, inst.x, inst.y)

          if hit then
            hit:dispatchEvent(inst)
          end
        elseif signal.KEYBOARD_SIGNALS[name] then
          local screen = self.keyboards[inst.keyboard]

          if screen then
            for _, document in ipairs(self.documents) do
              if document.display.screen == screen then
                document:dispatchEvent(inst, true)
              end
            end
          end
        else
          for _, document in ipairs(self.documents) do
            document:dispatchEvent(inst, true)
          end
        end

        self:render()
      end
    end
  end, debug.traceback)

  self:__destroy__()

  if not success then
    local message = ("Wonderful event loop crashed while running. Error:\n" ..
                     traceback)

    if thread.current() then
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

  return thread.create(self.run, self)
end

--- Stop the event loop.
function Wonderful:stop()
  self.running = false
  event.push("[" .. tostring(self) .. "] stop")
end

--- Destroy an instance of the main class.
-- Runs @{wonderful.display.DisplayManager:restore}, and cleans up.
function Wonderful:__destroy__()
  self.running = false
  self.displayManager:restore()
  self.displayManager.displays = {}
  self.documents = {}
end

---
-- @export
local module = {
  Wonderful = Wonderful,
}

return tableUtil.autoimport(module, "wonderful")

