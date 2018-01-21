local class = require("lua-objects")

local Event = require("wonderful.event").Event

local ComponentAdded = class(Event, {name = "wonderful.signal.ComponentAdded"})

function ComponentAdded:__new__(address, componentType)
  self:superCall(Event, "__new__")
  self.address = address
  self.componentType = componentType
end

local ComponentRemoved = class(
  Event,
  {name = "wonderful.signal.ComponentRemoved"}
)

function ComponentRemoved:__new__(address, componentType)
  self:superCall(Event, "__new__")
  self.address = address
  self.componentType = componentType
end

local ComponentAvailable = class(
  Event,
  {name = "wonderful.signal.ComponentAvailable"}
)

function ComponentAvailable:__new__(componentType)
  self:superCall(Event, "__new__")
  self.componentType = componentType
end

local ComponentUnavailable = class(
  Event,
  {name = "wonderful.signal.ComponentUnavailable"}
)

function ComponentUnavailable:__new__(componentType)
  self:superCall(Event, "__new__")
  self.componentType = componentType
end

local Touch = class(Event, {name = "wonderful.signal.Touch"})

function Touch:__new__(x, y, button, playerName)
  self:superCall(Event, "__new__")
  self.x = x
  self.y = y
  self.button = button
  self.playerName = playerName
end

local Drag = class(Event, {name = "wonderful.signal.Drag"})

function Drag:__new__(x, y, button, playerName)
  self:superCall(Event, "__new__")
  self.x = x
  self.y = y
  self.button = button
  self.playerName = playerName
end

local Drop = class(Event, {name = "wonderful.signal.Drop"})

function Drop:__new__(x, y, button, playerName)
  self:superCall(Event, "__new__")
  self.x = x
  self.y = y
  self.button = button
  self.playerName = playerName
end

local Scroll = class(Event, {name = "wonderful.signal.Scroll"})

function Scroll:__new__(x, y, direction, playerName)
  self:superCall(Event, "__new__")
  self.x = x
  self.y = y
  self.direction = direction
  self.playerName = playerName
end

local Walk = class(Event, {name = "wonderful.signal.Walk"})

function Walk:__new__(x, y, playerName)
  self:superCall(Event, "__new__")
  self.x = x
  self.y = y
  self.playerName = playerName
end

local KeyDown = class(Event, {name = "wonderful.signal.KeyDown"})

function KeyDown:__new__(keyboard, char, code, playerName)
  self:superCall(Event, "__new__")
  self.keyboard = keyboard
  self.char = char
  self.code = code
  self.playerName = playerName
end

local KeyUp = class(Event, {name = "wonderful.signal.KeyUp"})

function KeyUp:__new__(keyboard, char, code, playerName)
  self:superCall(Event, "__new__")
  self.keyboard = keyboard
  self.char = char
  self.code = code
  self.playerName = playerName
end

local Clipboard = class(Event, {name = "wonderful.signal.Clipboard"})

function Clipboard:__new__(keyboard, value, playerName)
  self:superCall(Event, "__new__")
  self.keyboard = keyboard
  self.value = value
  self.playerName = playerName
end

local RedstoneChanged = class(
  Event,
  {name = "wonderful.signal.RedstoneChanged"}
)

function RedstoneChanged:__new__(address, side, oldValue, newValue)
  self:superCall(Event, "__new__")
  self.address = address
  self.side = side
  self.oldValue = oldValue
  self.newValue = newValue
end

local Motion = class(Event, {name = "wonderful.signal.Motion"})

function Motion:__new__(address, relativeX, relativeY, relativeZ,
                        entityName)
  self:superCall(Event, "__new__")
  self.address = address
  self.relativeX = relativeX
  self.relativeY = relativeY
  self.relativeZ = relativeZ
  self.entityName = entityName
end

local ModemMessage = class(Event, {name = "wonderful.signal.ModemMessage"})

function ModemMessage:__new__(receiverAddress, senderAddress, port,
                              distance, ...)
  self:superCall(Event, "__new__")
  self.receiverAddress = receiverAddress
  self.senderAddress = senderAddress
  self.port = port
  self.distance = distance
  self.data = {...}
end

local InventoryChanged = class(
  Event,
  {name = "wonderful.signal.InventoryChanged"}
)

function InventoryChanged:__new__(slot)
  self:superCall(Event, "__new__")
  self.slot = slot
end

return {
  ComponentAdded = ComponentAdded,
  ComponentRemoved = ComponentRemoved,
  ComponentAvailable = ComponentAvailable,
  ComponentUnavailable = ComponentUnavailable,
  Touch = Touch,
  Drag = Drag,
  Drop = Drop,
  Scroll = Scroll,
  Walk = Walk,
  KeyDown = KeyDown,
  KeyUp = KeyUp,
  Clipboard = Clipboard,
  RedstoneChanged = RedstoneChanged,
  Motion = Motion,
  ModemMessage = ModemMessage,
  InventoryChanged = InventoryChanged
}

