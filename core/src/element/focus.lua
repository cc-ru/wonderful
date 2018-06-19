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

--- Focusing events.
-- @module wonderful.element.focus

local class = require("lua-objects")

local Event = require("wonderful.event").Event

--- The focus-in event.
local FocusIn = class(Event, {name = "wonderful.element.focus.FocusIn"})

--- The focus-in event.
-- @type FocusIn

--- The previously focused element. May be `nil`.
-- @field FocusIn.previous

--- Construct a new instance.
-- @param[opt] previous the previously focused element
function FocusIn:__new__(previous)
  self.previous = previous
end

--- @section end

--- The focus-out event.
local FocusOut = class(Event, {name = "wonderful.element.focus.FocusOut"})

--- The focus-out event.
-- @type FocusOut

--- The currently focused element. May be `nil`
-- @field FocusOut.new

--- Construct a new instance.
-- @param[opt] new the currently focused element
function FocusOut:__new__(new)
  self.new = new
end

--- @section end

--- @export
return {
  FocusIn = FocusIn,
  FocusOut = FocusOut,
}

