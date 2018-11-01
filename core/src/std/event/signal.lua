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
-- @module wonderful.std.event.signal

local class = require("lua-objects")

local Event = require("wonderful.event").Event

--- The base signal class.
-- @cl Signal
-- @extends wonderful.event.Event
local Signal = class(Event, {name = "wonderful.std.event.signal.Signal"})

--- The `"component_added"` signal.
-- @cl ComponentAdded
-- @extends Signal
local ComponentAdded = class(
  Signal,
  {name = "wonderful.std.event.signal.ComponentAdded"}
)

--- @type ComponentAdded

--- Construct a new instance.
-- @tparam string address a component address
-- @tparam string componentType a component type
function ComponentAdded:__new__(address, componentType)
  Signal.__new__(self)
  self._address = address
  self._componentType = componentType
end

function ComponentAdded:getAddress()
  return self._address
end

function ComponentAdded:getComponentType()
  return self._componentType
end

--- @section end

--- The `"component_removed"` signal.
-- @cl ComponentRemoved
-- @extends Signal
local ComponentRemoved = class(
  Signal,
  {name = "wonderful.std.event.signal.ComponentRemoved"}
)

--- @type ComponentRemoved

--- Construct a new instance.
-- @tparam string address a component address
-- @tparam string componentType a component type
function ComponentRemoved:__new__(address, componentType)
  Signal.__new__(self)
  self._address = address
  self._componentType = componentType
end

function ComponentRemoved:getAddress()
  return self._address
end

function ComponentRemoved:getComponentType()
  return self._componentType
end

--- @section end

--- The `"component_available"` signal.
-- @cl ComponentAvailable
-- @extends Signal
local ComponentAvailable = class(
  Signal,
  {name = "wonderful.std.event.signal.ComponentAvailable"}
)

--- @type ComponentAvailable

--- Construct a new instance.
-- @tparam string componentType a component type
function ComponentAvailable:__new__(componentType)
  Signal.__new__(self)
  self._componentType = componentType
end

function ComponentAvailable:getComponentType()
  return self._componentType
end

--- @section end

--- The `"component_unavailable"` signal.
-- @cl ComponentUnavailable
-- @extends Signal
local ComponentUnavailable = class(
  Signal,
  {name = "wonderful.std.event.signal.ComponentUnavailable"}
)

--- @type ComponentUnavailable

--- Construct a new instance.
-- @tparam string componentType a component type
function ComponentUnavailable:__new__(componentType)
  Signal.__new__(self)
  self._componentType = componentType
end

function ComponentUnavailable:getComponentType()
  return self._componentType
end

--- @section end

--- The `"touch"` signal.
-- @cl Touch
-- @extends Signal
local Touch = class(Signal, {name = "wonderful.std.event.signal.Touch"})

--- @type Touch

--- Construct a new instance.
-- @tparam string screen a screen address
-- @tparam number x a column number
-- @tparam number y a row number
-- @tparam int button a button number
-- @tparam ?string playerName a player name
function Touch:__new__(screen, x, y, button, playerName)
  Signal.__new__(self)
  self._screen = screen
  self._x = x
  self._y = y
  self._button = button
  self._playerName = playerName
end

function Touch:getScreen()
  return self._screen
end

function Touch:getX()
  return self._x
end

function Touch:getY()
  return self._y
end

function Touch:getButton()
  return self._button
end

function Touch:getPlayerName()
  return self._playerName
end

--- @section end

--- The `"drag"` signal.
-- @cl Drag
-- @extends Signal
local Drag = class(Signal, {name = "wonderful.std.event.signal.Drag"})

--- @type Drag

--- Construct a new instance.
-- @tparam string screen a screen address
-- @tparam number x a column number
-- @tparam number y a row number
-- @tparam int button a button number
-- @tparam ?string playerName a player name
function Drag:__new__(screen, x, y, button, playerName)
  Signal.__new__(self)
  self._screen = screen
  self._x = x
  self._y = y
  self._button = button
  self._playerName = playerName
end

function Drag:getScreen()
  return self._screen
end

function Drag:getX()
  return self._x
end

function Drag:getY()
  return self._y
end

function Drag:getButton()
  return self._button
end

function Drag:getPlayerName()
  return self._playerName
end

--- @section end

--- The `"drop"` signal.
-- @cl Drop
-- @extends Signal
local Drop = class(Signal, {name = "wonderful.std.event.signal.Drop"})

--- @type Drop

--- Construct a new instance.
-- @tparam string screen a screen address
-- @tparam number x a column number
-- @tparam number y a row number
-- @tparam int button a button number
-- @tparam ?string playerName a player name
function Drop:__new__(screen, x, y, button, playerName)
  Signal.__new__(self)
  self._screen = screen
  self._x = x
  self._y = y
  self._button = button
  self._playerName = playerName
end

function Drop:getScreen()
  return self._screen
end

function Drop:getX()
  return self._x
end

function Drop:getY()
  return self._y
end

function Drop:getButton()
  return self._button
end

function Drop:getPlayerName()
  return self._playerName
end

--- @section end

--- The `"scroll"` signal.
-- @cl Scroll
-- @extends Signal
local Scroll = class(Signal, {name = "wonderful.std.event.signal.Scroll"})

--- @type Scroll

--- Construct a new instance.
-- @tparam string screen a screen address
-- @tparam number x a column number
-- @tparam number y a row number
-- @tparam int direction a direction of scrolling
-- @tparam ?string playerName a player name
function Scroll:__new__(screen, x, y, direction, playerName)
  Signal.__new__(self)
  self._screen = screen
  self._x = x
  self._y = y
  self._direction = direction
  self._playerName = playerName
end

function Scroll:getScreen()
  return self._screen
end

function Scroll:getX()
  return self._x
end

function Scroll:getY()
  return self._y
end

function Scroll:getDirection()
  return self._direction
end

function Scroll:getPlayerName()
  return self._playerName
end

--- @section end

--- The `"key_down"` signal.
-- @cl KeyDown
-- @extends Signal
local KeyDown = class(Signal, {name = "wonderful.std.event.signal.KeyDown"})

--- @type KeyDown

--- Construct a new instance.
-- @tparam string keyboard a keyboard address
-- @tparam int char a character Unicode codepoint
-- @tparam int code a key code
-- @tparam ?string playerName a player name
function KeyDown:__new__(keyboard, char, code, playerName)
  Signal.__new__(self)
  self._keyboard = keyboard
  self._char = char
  self._code = code
  self._playerName = playerName
end

function KeyDown:getKeyboard()
  return self._keyboard
end

function KeyDown:getChar()
  return self._char
end

function KeyDown:getCode()
  return self._code
end

function KeyDown:getPlayerName()
  return self._playerName
end

--- @section end

--- The `"key_up"` signal.
-- @cl KeyUp
-- @extends Signal
local KeyUp = class(Signal, {name = "wonderful.std.event.signal.KeyUp"})

--- @type KeyUp

--- Construct a new instance.
-- @tparam string keyboard a keyboard address
-- @tparam int char a character Unicode codepoint
-- @tparam int code a key code
-- @tparam ?string playerName a player name
function KeyUp:__new__(keyboard, char, code, playerName)
  Signal.__new__(self)
  self._keyboard = keyboard
  self._char = char
  self._code = code
  self._playerName = playerName
end

function KeyUp:getKeyboard()
  return self._keyboard
end

function KeyUp:getChar()
  return self._char
end

function KeyUp:getCode()
  return self._code
end

function KeyUp:getPlayerName()
  return self._playerName
end

--- @section end

--- The `"clipboard"` signal.
-- @cl Clipboard
-- @extends Signal
local Clipboard = class(Signal, {name = "wonderful.std.event.signal.Clipboard"})

--- @type Clipboard

--- Construct a new instance.
-- @tparam string keyboard a keyboard address
-- @tparam string value an inserted string
-- @tparam string playerName a player name
function Clipboard:__new__(keyboard, value, playerName)
  Signal.__new__(self)
  self._keyboard = keyboard
  self._value = value
  self._playerName = playerName
end

function Clipboard:getKeyboard()
  return self._keyboard
end

function Clipboard:getValue()
  return self._value
end

function Clipboard:getPlayerName()
  return self._playerName
end

--- @section end

--- The `"interrupted"` signal.
local Interrupt = class(Signal, {name = "wonderful.std.event.signal.Interrupt"})

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

--- @export
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
  Interrupt = Interrupt,

  SCREEN_SIGNALS = SCREEN_SIGNALS,
  KEYBOARD_SIGNALS = KEYBOARD_SIGNALS,
}

