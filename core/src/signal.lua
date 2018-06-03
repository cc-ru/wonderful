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

--- Some common signals.
-- @module wonderful.signal

local class = require("lua-objects")

local Event = require("wonderful.event").Event

--- The base signal class.
-- @see wonderful.event.Event
local Signal = class(Event, {name = "wonderful.signal.Signal"})

--- The `"component_added"` signal.
local ComponentAdded = class(Signal, {name = "wonderful.signal.ComponentAdded"})

--- The `"component_added"` signal.
-- @type ComponentAdded

--- The component address.
-- @field ComponentAdded.address

--- The component type.
-- @field ComponentAdded.componentType

--- Construct a new instance.
-- @tparam string address a component address
-- @tparam string componentType a component type
function ComponentAdded:__new__(address, componentType)
  self:superCall(Signal, "__new__")
  self.address = address
  self.componentType = componentType
end

---
-- @section end

--- The `"component_removed"` signal.
local ComponentRemoved = class(
  Signal,
  {name = "wonderful.signal.ComponentRemoved"}
)

--- The `"component_removed"` signal.
-- @type ComponentRemoved

--- The component address.
-- @field ComponentRemoved.address

--- The component type.
-- @field ComponentRemoved.componentType

--- Construct a new instance.
-- @tparam string address a component address
-- @tparam string componentType a component type
function ComponentRemoved:__new__(address, componentType)
  self:superCall(Signal, "__new__")
  self.address = address
  self.componentType = componentType
end

---
-- @section end

--- The `"component_available"` signal.
local ComponentAvailable = class(
  Signal,
  {name = "wonderful.signal.ComponentAvailable"}
)

--- The `"component_available"` signal.
-- @type ComponentAvailable

--- The component type.
-- @field ComponentAvailable.componentType

--- Construct a new instance.
-- @tparam string componentType a component type
function ComponentAvailable:__new__(componentType)
  self:superCall(Signal, "__new__")
  self.componentType = componentType
end

---
-- @section end

--- The `"component_unavailable"` signal.
local ComponentUnavailable = class(
  Signal,
  {name = "wonderful.signal.ComponentUnavailable"}
)

--- The `"component_unavailable"` signal.
-- @type ComponentUnavailable

--- The component type.
-- @field ComponentUnavailable.componentType

--- Construct a new instance.
-- @tparam string componentType a component type
function ComponentUnavailable:__new__(componentType)
  self:superCall(Signal, "__new__")
  self.componentType = componentType
end

---
-- @section end

--- The `"touch"` signal.
local Touch = class(Signal, {name = "wonderful.signal.Touch"})

--- The `"touch"` signal.
-- @type Touch

--- The screen address.
-- @field Touch.screen

--- The column number.
-- @field Touch.x

--- The row number.
-- @field Touch.y

--- The button number.
-- @field Touch.button

--- The player name. May be absent.
-- @field Touch.playerName

--- Construct a new instance.
-- @tparam string screen a screen address
-- @tparam number x a column number
-- @tparam number y a row number
-- @tparam int button a button number
-- @tparam ?string playerName a player name
function Touch:__new__(screen, x, y, button, playerName)
  self:superCall(Signal, "__new__")
  self.screen = screen
  self.x = x
  self.y = y
  self.button = button
  self.playerName = playerName
end

---
-- @section end

--- The `"drag"` signal.
local Drag = class(Signal, {name = "wonderful.signal.Drag"})

--- The `"drag"` signal.
-- @type Drag

--- The screen address.
-- @field Drag.screen

--- The column number.
-- @field Drag.x

--- The row number.
-- @field Drag.y

--- The button number.
-- @field Drag.button

--- The player name. May be absent.
-- @field Drag.playerName

--- Construct a new instance.
-- @tparam string screen a screen address
-- @tparam number x a column number
-- @tparam number y a row number
-- @tparam int button a button number
-- @tparam ?string playerName a player name
function Drag:__new__(screen, x, y, button, playerName)
  self:superCall(Signal, "__new__")
  self.screen = screen
  self.x = x
  self.y = y
  self.button = button
  self.playerName = playerName
end

---
-- @section end

--- The `"drop"` signal.
local Drop = class(Signal, {name = "wonderful.signal.Drop"})

--- The `"drop"` signal.
-- @type Drop

--- The screen address.
-- @field Drop.screen

--- The column number
-- @field Drop.x

--- The row number
-- @field Drop.y

--- The button number
-- @field Drop.button

--- The player name. May be absent.
-- @field Drop.playerName

--- Construct a new instance.
-- @tparam string screen a screen address
-- @tparam number x a column number
-- @tparam number y a row number
-- @tparam int button a button number
-- @tparam ?string playerName a player name
function Drop:__new__(screen, x, y, button, playerName)
  self:superCall(Signal, "__new__")
  self.screen = screen
  self.x = x
  self.y = y
  self.button = button
  self.playerName = playerName
end

---
-- @section end

--- The `"scroll"` signal.
local Scroll = class(Signal, {name = "wonderful.signal.Scroll"})

--- The `"scroll"` signal.
-- @type Scroll

--- The screen address.
-- @field Scroll.screen

--- The column number.
-- @field Scroll.x

--- The row number.
-- @field Scroll.y

--- The direction of scrolling.
-- @field Scroll.direction

--- The player name. May be absent.
-- @field Scroll.playerName

--- Construct a new instance.
-- @tparam string screen a screen address
-- @tparam number x a column number
-- @tparam number y a row number
-- @tparam int direction a direction of scrolling
-- @tparam ?string playerName a player name
function Scroll:__new__(screen, x, y, direction, playerName)
  self:superCall(Signal, "__new__")
  self.screen = screen
  self.x = x
  self.y = y
  self.direction = direction
  self.playerName = playerName
end

---
-- @section end

--- The `"key_down"` signal.
local KeyDown = class(Signal, {name = "wonderful.signal.KeyDown"})

--- The `"key_down"` signal.
-- @type KeyDown

--- The keyboard address.
-- @field KeyDown.keyboard

--- The character Unicode codepoint.
-- @field KeyDown.char

--- The key code.
-- @field KeyDown.code

--- The player name. May be absent.
-- @field KeyDown.playerName

--- Construct a new instance.
-- @tparam string keyboard a keyboard address
-- @tparam int char a character Unicode codepoint
-- @tparam int code a key code
-- @tparam ?string playerName a player name
function KeyDown:__new__(keyboard, char, code, playerName)
  self:superCall(Signal, "__new__")
  self.keyboard = keyboard
  self.char = char
  self.code = code
  self.playerName = playerName
end

---
-- @section end

--- The `"key_up"` signal.
local KeyUp = class(Signal, {name = "wonderful.signal.KeyUp"})

--- The `"key_up"` signal.
-- @type KeyUp

--- The keyboard address.
-- @field KeyUp.keyboard

--- The character Unicode codepoint.
-- @field KeyUp.char

--- The key code.
-- @field KeyUp.code

--- The player name. May be absent.
-- @field KeyUp.player

--- Construct a new instance.
-- @tparam string keyboard a keyboard address
-- @tparam int char a character Unicode codepoint
-- @tparam int code a key code
-- @tparam ?string playerName a player name
function KeyUp:__new__(keyboard, char, code, playerName)
  self:superCall(Signal, "__new__")
  self.keyboard = keyboard
  self.char = char
  self.code = code
  self.playerName = playerName
end

---
-- @section end

--- The `"clipboard"` signal.
local Clipboard = class(Signal, {name = "wonderful.signal.Clipboard"})

--- The `"clipboard"` signal.
-- @type Clipboard

--- The keyboard address.
-- @field Clipboard.keyboard

--- The inserted string.
-- @field Clipboard.value

--- The player name.
-- @field Clipboard.playerName

--- Construct a new instance.
-- @tparam string keyboard a keyboard address
-- @tparam string value an inserted string
-- @tparam string playerName a player name
function Clipboard:__new__(keyboard, value, playerName)
  self:superCall(Signal, "__new__")
  self.keyboard = keyboard
  self.value = value
  self.playerName = playerName
end

---
-- @section end

--- The `"redstone_changed"` signal.
local RedstoneChanged = class(
  Signal,
  {name = "wonderful.signal.RedstoneChanged"}
)

--- The `"redstone_changed"` signal.
-- @type RedstoneChanged

--- The redstone component address.
-- @field RedstoneChanged.redstone

--- The side that had the redstone value changed.
-- @field RedstoneChanged.side

--- The previous redstone strength value.
-- @field RedstoneChanged.oldValue

--- The new redstone strength value.
-- @field RedstoneChanged.newValue

--- Construct a new instance.
-- @tparam string redstone a redstone component address
-- @tparam int side a side that had a redstone value changed
-- @tparam int oldValue a previous redstone strength value
-- @tparam int newValue a new redstone strength value
function RedstoneChanged:__new__(redstone, side, oldValue, newValue)
  self:superCall(Signal, "__new__")
  self.redstone = redstone
  self.side = side
  self.oldValue = oldValue
  self.newValue = newValue
end

---
-- @section end

--- The `"motion"` signal.
local Motion = class(Signal, {name = "wonderful.signal.Motion"})

--- The `"motion"` signal.
-- @type Motion

--- The motion sensor address.
-- @field Motion.motionSensor

--- The relative x coordinate.
-- @field Motion.relativeX

--- The relative y coordinate.
-- @field Motion.relativeY

--- The relative z coordinate.
-- @field Motion.relativeZ

--- The entity name.
-- @field Motion.entityName

--- Construct a new instance.
-- @tparam string motionSensor a motion sensor address
-- @tparam number relativeX a relative x coordinate
-- @tparam number relativeY a relative y coordinate
-- @tparam number relativeZ a relative z cooridnate
-- @tparam string entityName an entity name
function Motion:__new__(motionSensor, relativeX, relativeY, relativeZ,
                        entityName)
  self:superCall(Signal, "__new__")
  self.motionSensor = motionSensor
  self.relativeX = relativeX
  self.relativeY = relativeY
  self.relativeZ = relativeZ
  self.entityName = entityName
end

---
-- @section end

--- The `"modem_message"` signal.
local ModemMessage = class(Signal, {name = "wonderful.signal.ModemMessage"})

--- The `"modem_message"` signal.
-- @type ModemMessage

--- The receiving modem address.
-- @field ModemMessage.receiver

--- The source modem address.
-- @field ModemMessage.source

--- The port.
-- @field ModemMessage.port

--- The distance.
-- @field ModemMessage.distance

--- The message data.
-- @field ModemMessage.data

--- Construct a new instance.
-- @tparam string receiver a receiving modem address
-- @tparam string sender a source modem address
-- @tparam int port a port
-- @tparam int distance a distance
-- @param ... packet parts
function ModemMessage:__new__(receiver, sender, port, distance, ...)
  self:superCall(Signal, "__new__")
  self.receiver = receiver
  self.sender = sender
  self.port = port
  self.distance = distance
  self.data = {...}
end

---
-- @section end

--- The `"inventory_changed"` signal.
local InventoryChanged = class(
  Signal,
  {name = "wonderful.signal.InventoryChanged"}
)

--- The `"inventory_changed"` signal.
-- @type InventoryChanged

--- The slot number.
-- @field InventoryChanged.slot

--- Construct a new instance.
-- @tparam int slot a slot number
function InventoryChanged:__new__(slot)
  self:superCall(Signal, "__new__")
  self.slot = slot
end

---
-- @section end

--- The screen signals.
-- They are only sent to documents that are displayed on the screen that issued
-- them. Additionally, @{wonderful.Wonderful:hit|Wonderful:hit} is used to
-- dispatch them.
local SCREEN_SIGNALS = {
  ["touch"] = true,
  ["drag"] = true,
  ["drop"] = true,
  ["scroll"] = true
}

--- The keyboard signals.
-- They are only sent to document that listen on the keyboard that issues them.
local KEYBOARD_SIGNALS = {
  ["key_down"] = true,
  ["key_up"] = true,
  ["clipboard"] = true
}

---
-- @export
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

