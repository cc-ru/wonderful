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

--- Base classes of the wonderful's event system.
-- @module wonderful.event

local class = require("lua-objects")

local tableUtil = require("wonderful.util.table")

--- The enum of event handling phases.
-- @field None the default state, when an event hasn't been dispatched yet.
-- @field Capturing TODO
-- @field AtTarget an event is being handled to a listener.
-- @field Bubbling an event is being propagated to children.
local EventPhase = {
  None = 0,
  Capturing = 1,
  AtTarget = 2,
  Bubbling = 3
}

--- The base event class.
-- @see wonderful.event.EventTarget
local Event = class(nil, {name = "wonderful.event.Event"})

--- The base event class.
-- @type Event

--- Whether the event has been cancelled.
-- @field Event.cancelled
-- @see wonderful.event.Event:cancel

--- Whether the propagation has been stopped.
-- @field Event.propagationStopped
-- @see wonderful.event.Event:stopPropagation

--- Whether the default listener has been prevented from running.
-- @field Event.defaultPrevented
-- @see wonderful.event.Event:preventDefault

--- The current phase of event handling.
-- @field Event.phase

--- Construct a new instance.
function Event:__new__()
  self.cancelled = false
  self.propagationStopped = false
  self.defaultPrevented = false

  self.phase = EventPhase.None
end

--- Cancel the event.
-- The event will still be bubbled to the children, but other listeners
-- added for the current class won't be run.
function Event:cancel()
  self.cancelled = true
end

--- Stop propagation of the event.
-- The event listeners for the event will still be run, but it won't be
-- propagated to the children.
function Event:stopPropagation()
  self.propagationStopped = true
end

--- Prevent the default listener from running.
-- @see wonderful.event.EventTarget:setDefaultEventListener
function Event:preventDefault()
  self.defaultPrevented = true
end

---
-- @section end

--- The base event target class.
-- @see wonderful.event.Event
local EventTarget = class(nil, {name = "wonderful.event.EventTarget"})

--- The base event target class.
-- @type EventTarget

--- Construct a new instance.
function EventTarget:__new__()
  self.listeners = {}
  self.defaultListeners = {}
end

--- Add an event listener.
-- @param cls a class that inherits from @{wonderful.event.Event}
-- @tparam function handler a handler function
-- @tparam table options a table of listener options
-- @tparam boolean options.once whether to only run the handler once
-- @tparam boolean options.capture TODO
function EventTarget:addEventListener(cls, handler, options)
  if not self.listeners[cls] then
    self.listeners[cls] = {}
  end

  local listener = tableUtil.shallowcopy(options or {})
  listener.handler = handler

  table.insert(self.listeners[cls], listener)
end

--- Remove an event listener.
-- @param cls a class that inherits from @{wonderful.event.Event}
-- @tparam function handler a handler function
-- @tparam table options a table of the listener options
-- @tparam boolean options.once whether to only run the handler one
-- @tparam boolean options.capture TODO
-- @treturn boolean whether there was a listener that matched the query and was removed
-- @see wonderful.event.EventTarget:addEventListener
function EventTarget:removeEventListener(cls, handler, options)
  if not self.listeners[cls] then
    return false
  end

  local query = tableUtil.shallowcopy(options or {})
  query.handler = query

  for i, listener in ipairs(self.listeners[cls]) do
    if tableUtil.shalloweq(listener, query) then
      table.remove(self.listeners, i)
      return true
    end
  end

  return false
end

--- Set a default event listener for an event.
-- @param cls a class that inherits from @{wonderful.event.Event}
-- @tparam function handler a handler function
-- @tparam table options a table of listener options
-- @tparam boolean options.capture TODO
function EventTarget:setDefaultEventListener(cls, handler, options)
  local listener = tableUtil.shallowcopy(options or {})
  listener.handler = handler

  self.defaultListeners[cls] = listener
end

--- Remove a default event listener.
-- @param cls a class that inherits from @{wonderful.event.Event}
-- @see wonderful.event.EventTarget:setDefaultEventListener
function EventTarget:removeDefaultEventListener(cls)
  self.defaultListeners[cls] = nil
end

--- An abstract getter of a capturing parent.
-- @return the capturing parent
function EventTarget:getCapturingParent()
  error("unimplemented abstract method EventTarget:getCapturingParent")
end

--- An abstract getter of bubbling children.
-- @treturn table a table of bubbling children
function EventTarget:getBubblingChildren()
  error("unimplemented abstract method EventTarget:getBubblingChildren")
end

--- Dispatch an @{wonderful.event.Event|Event} instance, running handlers.
-- @param event an instance of a class that inherits from @{wonderful.event.Event}
function EventTarget:dispatchEvent(event)
  for i, listener in ipairs(self.listeners[event.class]) do
    self:_handleEvent(listener, event)

    if listener.once then
      table.remove(self.listeners[event.class], i)
    end

    if event.cancelled then
      break
    end
  end

  if not event.defaultPrevented and self.defaultListeners[event.class] then
    self:_handleEvent(self.defaultListeners[event.class], event)
  end
end

function EventTarget:_handleEvent(listener, event)
  event.target = self

  if listener.capture then
    event.phase = EventPhase.Capturing

    local parent = self:getCapturingParent()

    if parent then
      event.currentTarget = parent
      parent:dispatchEvent(event)
    end
  end

  event.phase = EventPhase.AtTarget
  event.currentTarget = self
  listener.handler(self, event)

  event.phase = EventPhase.Bubbling

  for _, child in ipairs(self:getBubblingChildren()) do
    if event.propagationStopped then
      break
    end

    event.currentTarget = child
    child:dispatchEvent(event)
  end
end

---
-- @export
return {
  EventPhase = EventPhase,
  Event = Event,
  EventTarget = EventTarget,
}

