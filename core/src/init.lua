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
function Wonderful:__new__()
  self.displayManager = display.DisplayManager()
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
  end

  local display = self.displayManager:newDisplay {
    box = args.box,
    screen = args.screen
  }

  local document = document.Document {
    style = args.style,
    display = display
  }

  table.insert(self.documents, document)
  return document
end

do
  local function rStackingContext(root)
    local buf = root.display.fb

    for _, el in root.stackingContext.iter do
      if el.isLeaf or el.stackingContext == root.stackingContext then
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

          if view then
            el:render(view)
          end
        end
      else
        rStackingContext(el)
      end
    end
  end

  function Wonderful:render()
    for _, document in ipairs(self.documents) do
      rStackingContext(document)
    end

    for _, display in ipairs(self.displayManager.displays) do
      display:flush()
    end
  end
end

do
  local function hStackingContext(root)
    for _, el in root.stackingContext.iterRev do
      if el.isLeaf or el.stackingContext == root.stackingContext then
        if el.calculatedBox:has(x, y) then
          return el
        end
      else
        local hit = hStackingContext(el)

        if hit then
          return hit
        end
      end
    end
  end

  --- Trace a "hit": find an element by touch coordinates.
  -- @tparam string screen a screen address
  -- @tparam number x a column number
  -- @tparam number y a row number
  -- @return an element
  function Wonderful:hit(screen, x, y)
    for _, document in ipairs(self.documents) do
      if document.display.screen == screen and
         document.display.box:has(x, y) then

        local hit = hStackingContext(document, x, y)

        if hit then
          return hit
        end
      end
    end
  end
end

--- Add a new signal to dispatch.
-- @tparam string name a signal name
-- @param cls a @{wonderful.signal.Signal} class
function Wonderful:addSignal(name, cls)
  self.signals[name] = cls
end

--- Run the event loop.
function Wonderful:run()
  self.running = true

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
        local screen = self.keyboards[screen]

        if screen then
          for _, document in ipairs(self.documents) do
            if document.display.screen == screen then
              document:dispatchEvent(inst)
            end
          end
        end
      else
        for _, document in ipairs(self.documents) do
          document:dispatchEvent(inst)
        end
      end

      self:render()
    end
  end
end

--- Stop the event loop.
function Wonderful:stop()
  self.running = false
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

return tableUtil.autoimport(export, "wonderful")

