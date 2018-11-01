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

--- A trapped flag class.
-- @module wonderful.util.flag

local class = require("lua-objects")

--- A trapped flag class.
--
-- Like a usual flag, it stores a boolean value. When the flag is raised, its
-- ascendants are notified of this, and calling their `isSetOff` method
-- returns `true`.
--
-- Note that, if you lower the flag, its ascendants **are not** notified of
-- this, and `isSetOff` keeps returning `true` until you `reset` them.
--
-- @cl wonderful.util.flag.TrappedFlag
local TrappedFlag = class(nil, {name = "wonderful.util.flag.TrappedFlag"})

--- @type TrappedFlag

--- Construct a new flag instance.
-- @tparam function(arg) parentFlagGetter a function that returns the parent
-- flag
-- @tparam boolean initialFlagValue the initial flag value
-- @tparam boolean initialTrapStatus the initial trap status (`true` if set off)
-- @param arg an argument to pass to the parent flag getter
function TrappedFlag:__new__(parentFlagGetter, initialFlagValue,
                             initialTrapStatus, arg)
  self._parentFlagGetter = parentFlagGetter
  self._getterArg = arg
  self._value = initialFlagValue
  self._isSetOff = initialTrapStatus
end

--- Raise the flag, and notify the parent of this change unless `quiet` is
-- `true`.
--
-- @tparam[opt=false] boolean quiet don't notify parent of the change
function TrappedFlag:raise(quiet)
  self._value = true

  if not quiet then
    self:_setParentOff()
  end
end

--- Lower the flag.
function TrappedFlag:lower()
  self._value = false
end

--- Check if the flag is raised.
-- @treturn boolean
function TrappedFlag:isRaised()
  return self._value
end

--- Check if the trap is set off.
-- @treturn boolean
function TrappedFlag:isSetOff()
  return self._isSetOff
end

--- Reset the trap.
--
-- This does not lower the flag.
function TrappedFlag:reset()
  self._isSetOff = false
end

function TrappedFlag:_getParentFlag()
  return self._parentFlagGetter(self._getterArg)
end

function TrappedFlag:_setParentOff()
  local parent = self:_getParentFlag()

  if parent then
    -- Do tail recursion.
    return parent:_setOff()
  end
end

function TrappedFlag:_setOff()
  if self._isSetOff then
    -- Stop if the trap was already triggered.
    return
  end

  self._isSetOff = true

  -- Do tail recursion.
  return self:_setParentOff()
end

--- @export
return {
  TrappedFlag = TrappedFlag,
}
