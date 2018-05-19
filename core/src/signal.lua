--- Some common signals.
-- @module wonderful.signal

local class = require("lua-objects")

local Event = require("wonderful.event").Event

local Signal = class(Event, {name = "wonderful.signal.Signal"})

local ComponentAdded = class(Signal, {name = "wonderful.signal.ComponentAdded"})

function ComponentAdded:__new__(address, componentType)
  self:superCall(Signal, "__new__")
  self.address = address
  self.componentType = componentType
end

local ComponentRemoved = class(
  Signal,
  {name = "wonderful.signal.ComponentRemoved"}
)

function ComponentRemoved:__new__(address, componentType)
  self:superCall(Signal, "__new__")
  self.address = address
  self.componentType = componentType
end

local ComponentAvailable = class(
  Signal,
  {name = "wonderful.signal.ComponentAvailable"}
)

function ComponentAvailable:__new__(componentType)
  self:superCall(Signal, "__new__")
  self.componentType = componentType
end

local ComponentUnavailable = class(
  Signal,
  {name = "wonderful.signal.ComponentUnavailable"}
)

function ComponentUnavailable:__new__(componentType)
  self:superCall(Signal, "__new__")
  self.componentType = componentType
end

local Touch = class(Signal, {name = "wonderful.signal.Touch"})

function Touch:__new__(screen, x, y, button, playerName)
  self:superCall(Signal, "__new__")
  self.screen = screen
  self.x = x
  self.y = y
  self.button = button
  self.playerName = playerName
end

local Drag = class(Signal, {name = "wonderful.signal.Drag"})

function Drag:__new__(screen, x, y, button, playerName)
  self:superCall(Signal, "__new__")
  self.screen = screen
  self.x = x
  self.y = y
  self.button = button
  self.playerName = playerName
end

local Drop = class(Signal, {name = "wonderful.signal.Drop"})

function Drop:__new__(screen, x, y, button, playerName)
  self:superCall(Signal, "__new__")
  self.screen = screen
  self.x = x
  self.y = y
  self.button = button
  self.playerName = playerName
end

local Scroll = class(Signal, {name = "wonderful.signal.Scroll"})

function Scroll:__new__(screen, x, y, direction, playerName)
  self:superCall(Signal, "__new__")
  self.screen = screen
  self.x = x
  self.y = y
  self.direction = direction
  self.playerName = playerName
end

local KeyDown = class(Signal, {name = "wonderful.signal.KeyDown"})

function KeyDown:__new__(keyboard, char, code, playerName)
  self:superCall(Signal, "__new__")
  self.keyboard = keyboard
  self.char = char
  self.code = code
  self.playerName = playerName
end

local KeyUp = class(Signal, {name = "wonderful.signal.KeyUp"})

function KeyUp:__new__(keyboard, char, code, playerName)
  self:superCall(Signal, "__new__")
  self.keyboard = keyboard
  self.char = char
  self.code = code
  self.playerName = playerName
end

local Clipboard = class(Signal, {name = "wonderful.signal.Clipboard"})

function Clipboard:__new__(keyboard, value, playerName)
  self:superCall(Signal, "__new__")
  self.keyboard = keyboard
  self.value = value
  self.playerName = playerName
end

local RedstoneChanged = class(
  Signal,
  {name = "wonderful.signal.RedstoneChanged"}
)

function RedstoneChanged:__new__(redstone, side, oldValue, newValue)
  self:superCall(Signal, "__new__")
  self.redstone = redstone
  self.side = side
  self.oldValue = oldValue
  self.newValue = newValue
end

local Motion = class(Signal, {name = "wonderful.signal.Motion"})

function Motion:__new__(motionSensor, relativeX, relativeY, relativeZ,
                        entityName)
  self:superCall(Signal, "__new__")
  self.motionSensor = motionSensor
  self.relativeX = relativeX
  self.relativeY = relativeY
  self.relativeZ = relativeZ
  self.entityName = entityName
end

local ModemMessage = class(Signal, {name = "wonderful.signal.ModemMessage"})

function ModemMessage:__new__(receiver, sender, port, distance, ...)
  self:superCall(Signal, "__new__")
  self.receiver = receiver
  self.sender = sender
  self.port = port
  self.distance = distance
  self.data = {...}
end

local InventoryChanged = class(
  Signal,
  {name = "wonderful.signal.InventoryChanged"}
)

function InventoryChanged:__new__(slot)
  self:superCall(Signal, "__new__")
  self.slot = slot
end

local SCREEN_SIGNALS = {
  ["touch"] = true,
  ["drag"] = true,
  ["drop"] = true,
  ["scroll"] = true
}

local KEYBOARD_SIGNALS = {
  ["key_down"] = true,
  ["key_up"] = true,
  ["clipboard"] = true
}

return {
  Signal = Signal,
  ComponentAdded = ComponentAdded,
  ComponentRemoved = ComponentRemoved,
  ComponentAvailable = ComponentAvailable,
  ComponentUnavailable = ComponentUnavailable,
  Touch = Touch,
  Drag = Drag,
  Drop = Drop,
  Scroll = Scroll,
  KeyDown = KeyDown,
  KeyUp = KeyUp,
  Clipboard = Clipboard,
  RedstoneChanged = RedstoneChanged,
  Motion = Motion,
  ModemMessage = ModemMessage,
  InventoryChanged = InventoryChanged,

  SCREEN_SIGNALS = SCREEN_SIGNALS,
  KEYBOARD_SIGNALS = KEYBOARD_SIGNALS,
}

