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

--- The wonderful's event system.
-- @module wonderful.event

local class = require("lua-objects")

local tableUtil = require("wonderful.util.table")

--- The enumeration of event phases.
--
-- An event generally goes through all of the phases, in the following order:
-- None (just created, not yet dispatched), Capturing (dispatches at the root,
-- and goes down the tree to the target; dispatches at the target as well),
-- Bubbling (dispatches at the target, and goes up the tree to the root,
-- inclusive).
--
-- Note that some phases may be skipped.
local EventPhase = {
  None = 0,  -- The default phase.
  Capturing = 1,  -- The event is descending the tree from its root to the target.
  Bubbling = 2,  -- The event is ascending the tree from the target to the root.
}

--- The base event class, which represents an event.
local Event = class(nil, {name = "wonderful.event.Event"})

--- The base event class, which represents an event.
-- @type Event

--- Whether the event can be canceled.
Event.cancelable = true

--- Whether the event runs event listeners at bubbling phase.
Event.bubblable = true

--- Whether the event runs event listeners at capturing phase.
Event.capturable = true

--- Whether propagation has been stopped.
Event.canceled = false

--- Whether the default listeners has been prevented from running.
Event.defaultPrevented = false

--- The current phase.
Event.phase = EventPhase.None

--- The event target.
Event.target = nil

--- Prevent the default listeners from running.
--
-- If a default listener has the `before` attribute set, its `onCancel` callback
-- will be called.
--
-- Note that this **does not** stop propagation of the event.
--
-- @see Event:cancel
function Event:preventDefault()
  self.defaultPrevented = true
end

--- Cancel the event, which stops propagation of the event.
--
-- Note that this **does not** prevent other listeners defined of the current
-- target from running, including the default listeners.
--
-- @see Event:preventDefault
function Event:cancel()
  if self.cancelable then
    self.canceled = true
  end
end

--- @section end

--- The event listener class.
local EventListener = class(nil, {name = "wonderful.event.EventListener"})

--- The event listener class.
-- @type EventListener

--- The event target the listener is assigned to.
-- @field EventListener.target

--- The event to which the listener is assigned to.
-- @field EventListener.event

--- The handler function, called when the listener catches the event.
-- @field EventListener.handler

--- Whether the listener is default.
-- @field EventListener.default

--- Whether the listener is executed before user-defined listeners.
-- @field EventListener.before

--- The function to call if the listener is canceled. **Rewritable**.
-- @field EventListener.onCancel

--- Whether the listener is executed at the capture phase.
-- @field EventListener.capture

--- Construct a new instance.
--
-- You don't usually need to instantiate this class directly.
--
-- @tparam table args a keyword argument table
-- @param args.target a event target the listener is attached to
-- @param args.event an `Event` subclass
-- @tparam function(target,event,handler) args.handler a handler function
-- @tparam boolean args.default whether this is a default listener
-- @tparam[opt=false] boolean args.before whether to run it before the user listeners
-- @tparam[optchain] function(target,event,handler) args.onCancel a function to run if the default action gets prevented
-- @tparam[opt=false] boolean args.capture whether to run it at capturing phase
function EventListener:__new__(args)
  self.target = args.target
  self.event = args.event
  self.handler = args.handler
  self.default = not not args.default
  self.before = self.default and not not args.before
  self._onCancel = self.before and args.onCancel or nil
  self.capture = not not args.capture
end

--- Removes the listener from the event target it's attached to.
function EventListener:remove()
  self.target:_removeEventListener(self)
end

function EventListener:__tostring__()
  return ("%s {target = <%s>, event = <%s>, handler = %s, default = %s, " ..
          "before = %s, onCancel = %s, capture = %s"):format(
    self.NAME,
    tostring(self.target),
    tostring(self.event),
    tostring(self.handler),
    tostring(self.default),
    tostring(self.before),
    tostring(self.onCancel),
    tostring(self.capture)
  )
end

function EventListener.__getters:onCancel()
  return self._onCancel
end

function EventListener.__setters:onCancel(value)
  if self.before then
    self._onCancel = value
  end
end

--- @section end

--- The base event target class.
local EventTarget = class(nil, {name = "wonderful.event.EventTarget"})

--- The base event target class.
-- @type EventTarget

--- Construct a new instance.
function EventTarget:__new__()
  self.eventListeners = {}
end

--- Add a default event listener for the class.
-- @tparam table args a keyword argument table
-- @param args.event an `Event` subclass
-- @tparam function(target,event,handler) args.handler a handler function
-- @tparam[opt=false] boolean args.before whether to run it before the user listeners
-- @tparam[optchain] function(target,event,handler) args.onCancel a function to run if the default action gets prevented
-- @tparam[opt=false] boolean args.capture whether to run it at capturing phase
-- @treturn EventListener the listener instance
function EventTarget:addDefaultListener(args)
  local listener = EventListener({
    target = self,
    event = args.event,
    handler = args.handler,
    default = true,
    before = args.before,
    onCancel = args.onCancel,
    capture = args.capture,
  })

  if not self.eventListeners[listener.event] then
    self.eventListeners[listener.event] = {}
  end

  table.insert(self.eventListeners[listener.event], listener)

  return listener
end

--- Add an event listener for the class.
-- @tparam table args a keyword argument table
-- @param args.event an `Event` subclass
-- @tparam function(target,event,handler) args.handler a handler function
-- @tparam[opt=false] boolean args.capture whether to run it at capturing phase
-- @treturn EventListener the listener instance
function EventTarget:addListener(args)
  local listener = EventListener({
    target = self,
    event = args.event,
    handler = args.handler,
    default = false,
    before = false,
    onCancel = nil,
    capture = args.capture,
  })

  if not self.eventListeners[listener.event] then
    self.eventListeners[listener.event] = {}
  end

  table.insert(self.eventListeners[listener.event], listener)

  return listener
end

--- Find a listener by its params.
-- @tparam table args a keyword argument table
-- @param args.event the event to which the listener is assigned
-- @tparam function(target,event,handler) args.handler the handler function
-- @tparam[opt=false] boolean args.default whether the listener is default
-- @tparam[opt=false] boolean args.before whether the listener runs before user-defined listeners
-- @tparam[optchain] function(target,event,handler) args.onCancel the function that runs if the default action gets prevented
-- @tparam[opt=false] boolean args.capture whether the listener is run at capturing phase
-- @treturn[1] EventListener the listener
-- @treturn[2] nil no such listener
function EventTarget:findListener(args)
  local event = args.event or error("event not specified", 1)
  local handler = args.handler or error("handler not specified", 1)
  local default = not not args.default
  local before = default and not not args.before
  local onCancel = before and args.onCancel
  local capture = not not args.capture

  local _, listener = tableUtil.first(self.eventListeners[event], function(v)
    return (
      v.event == event and
      v.handler == handler and
      v.default == default and
      v.before == before and
      v.onCancel == onCancel and
      v.capture == capture
    )
  end)

  return listener
end

--- Remove all defined event listeners.
-- @tparam[opt=false] boolean default whether to remove default listeners as well
function EventTarget:removeAllListeners(default)
  if default then
    self.eventListeners = {}

    return
  end

  for _, listeners in pairs(self.eventListeners) do
    for idx = #listeners, 1, -1 do
      if not listeners[idx].default then
        table.remove(listeners, idx)
      end
    end
  end
end

--- Abstract getter of child event targets.
-- @treturn {EventTarget,...} the children
function EventTarget:getChildEventTargets()
  error("abstract method EventTarget:getChildEventTargets left unimplemented")
end

--- Abstract getter of a parent event target.
-- @treturn EventTarget the parent
function EventTarget:getParentEventTarget()
  error("abstract method EventTarget:getParentEventTarget left unimplemented")
end

--- Dispatch an event at this event target.
--
-- Flood dispatch means that the event propagates to the entire element tree:
-- depth-first, pre-order, left-to-right when capturing, and depth-first,
-- post-order, right-to-left when bubbling. If the event is canceled, the
-- propagation stops at that element.
--
-- @param event the event to dispatch
-- @tparam boolean flood whether to use flood dispatch
-- @treturn boolean whether the propagation was stopped
function EventTarget:dispatchEvent(event, flood)
  event.phase = EventPhase.None

  if not flood then
    -- Build the event propagation path
    local path = {self}

    local element, parent = self

    while true do
      parent = element:getParentEventTarget()

      if not parent then
        break
      end

      table.insert(path, parent)
      element = parent
    end

    if event.capturable then
      event.phase = EventPhase.Capturing

      for i = #path, 1, -1 do
        event.target = path[i]
        event.defaultPrevented = false

        path[i]:_dispatchEvent(event)

        if event.canceled then
          return true
        end
      end
    end

    if event.bubblable then
      event.phase = EventPhase.Bubbling

      for i = 1, #path, 1 do
        event.target = path[i]
        event.defaultPrevented = false

        path[i]:_dispatchEvent(event)

        if event.canceled then
          return true
        end
      end
    end

    return false
  else
    -- flood dispatch
    local function dispatchCapture(element)
      event.target = element
      event.defaultPrevented = false

      element:_dispatchEvent(event)

      for _, child in ipairs(element:getChildEventTargets()) do
        if event.canceled then
          return true
        end

        dispatchCapture(child)
      end
    end

    local function dispatchBubbling(element)
      event.target = element
      event.defaultPrevented = false

      local children = element:getChildEventTargets()

      for i = #children, 1, -1 do
        dispatchBubbling(children[i])

        if event.canceled then
          return true
        end
      end

      element:_dispatchEvent(event)
    end

    if event.capturable then
      event.phase = EventPhase.Capturing

      if dispatchCapture(self) then
        return true
      end
    end

    if event.bubblable then
      event.phase = EventPhase.Bubbling

      if dispatchBubbling(self) then
        return true
      end
    end
  end
end

function EventTarget:_removeEventListener(listener)
  local removed = not not tableUtil.removeFirst(
    self.eventListeners[listener.event],
    listener
  )

  if removed and #self.eventListeners[listener.event] == 0 then
    self.eventListeners[listener.event] = nil
  end

  return removed
end

function EventTarget:_dispatchEvent(event)
  if not self.eventListeners[event.class] then
    return
  end

  local queue = {}
  local before, user, default = 1, 1, 1

  for _, listener in ipairs(self.eventListeners[event.class]) do
    if event.phase == EventPhase.Capturing and listener.capture or
        event.phase == EventPhase.Bubbling and not listener.capture then
      if not listener.default then
        table.insert(queue, user, listener)
        user = user + 1
        default = default + 1
      elseif not listener.before then
        table.insert(queue, default, listener)
        default = default + 1
      else
        table.insert(queue, before, listener)
        before = before + 1
        user = user + 1
        default = default + 1
      end
    end
  end

  for idx, listener in ipairs(queue) do
    if idx <= default and not event.canceled and
        (idx > before and idx <= user or not event.defaultPrevented) then
      -- run default-before (if not prevented), user, and default (if not
      -- prevented) listeners

      listener.handler(self, event, listener)

      if idx <= before and listener.onCancel then
        -- if the default-before listener has an on-cancel callback, add it to
        -- the end of the queue again
        table.insert(queue, listener)
      end
    elseif event.defaultPrevented and idx > default then
      -- if the default listeners are prevented, run on-cancel callbacks
      listener.onCancel(self, event, listener)
    end
  end
end

--- @export
return {
  EventPhase = EventPhase,
  Event = Event,
  EventListener = EventListener,
  EventTarget = EventTarget,
}
