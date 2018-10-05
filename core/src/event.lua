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
-- @cl Event
local Event = class(nil, {name = "wonderful.event.Event"})

--- @type Event

--- Whether the event can be canceled.
Event.cancelable = true

--- Whether the event runs event listeners at bubbling phase.
Event.bubblable = true

--- Whether the event runs event listeners at capturing phase.
Event.capturable = true

Event._canceled = false
Event._defaultPrevented = false
Event._phase = EventPhase.None
Event._target = nil

--- Prevent the default listeners from running.
--
-- If a default listener has the `before` attribute set, its `onCancel` callback
-- will be called.
--
-- Note that this **does not** stop propagation of the event.
--
-- @see Event:cancel
function Event:preventDefault()
  self._defaultPrevented = true
end

--- Cancel the event, which stops propagation of the event.
--
-- Note that this **does not** prevent other listeners defined of the current
-- target from running, including the default listeners.
--
-- @see Event:preventDefault
function Event:cancel()
  if self.cancelable then
    self._canceled = true
  end
end

function Event:isCanceled()
  return self._canceled
end

function Event:isDefaultPrevented()
  return self._defaultPrevented
end

function Event:getPhase()
  return self._phase
end

function Event:getTarget()
  return self._target
end

--- @section end

--- The event listener class.
-- @cl EventListener
local EventListener = class(nil, {name = "wonderful.event.EventListener"})

--- @type EventListener

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
  self._target = args.target
  self._event = args.event
  self._handler = args.handler
  self._default = not not args.default
  self._before = self.default and not not args.before
  self._onCancel = self._before and args.onCancel or nil
  self._capture = not not args.capture
end

--- Removes the listener from the event target it's attached to.
function EventListener:remove()
  self._target:_removeEventListener(self)
end

function EventListener:__tostring__()
  return ("%s {target = <%s>, event = <%s>, handler = %s, default = %s, " ..
          "before = %s, onCancel = %s, capture = %s"):format(
    self.NAME,
    tostring(self._target),
    tostring(self._event),
    tostring(self._handler),
    tostring(self._default),
    tostring(self._before),
    tostring(self._onCancel),
    tostring(self._capture)
  )
end

function EventListener:getCancelHandler()
  return self._onCancel
end

function EventListener:setCancelHandler(value)
  if self._before then
    self._onCancel = value
  end
end

function EventListener:getTarget()
  return self._target
end

function EventListener:getEvent()
  return self._event
end

function EventListener:getHandler()
  return self._handler
end

function EventListener:isDefault()
  return self._default
end

function EventListener:isRunBefore()
  return self._before
end

function EventListener:isCapturing()
  return self._capture
end

--- @section end

--- The base event target class.
-- @cl EventTarget
local EventTarget = class(nil, {name = "wonderful.event.EventTarget"})

--- @type EventTarget

--- Construct a new instance.
function EventTarget:__new__()
  self._eventListeners = {}
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
  local listener = EventListener {
    target = self,
    event = args.event,
    handler = args.handler,
    default = true,
    before = args.before,
    onCancel = args.onCancel,
    capture = args.capture,
  }

  if not self._eventListeners[listener:getEvent()] then
    self._eventListeners[listener:getEvent()] = {}
  end

  table.insert(self._eventListeners[listener:getEvent()], listener)

  return listener
end

--- Add an event listener for the class.
-- @tparam table args a keyword argument table
-- @param args.event an `Event` subclass
-- @tparam function(target,event,handler) args.handler a handler function
-- @tparam[opt=false] boolean args.capture whether to run it at capturing phase
-- @treturn EventListener the listener instance
function EventTarget:addListener(args)
  local listener = EventListener {
    target = self,
    event = args.event,
    handler = args.handler,
    default = false,
    before = false,
    onCancel = nil,
    capture = args.capture,
  }

  if not self._eventListeners[listener:getEvent()] then
    self._eventListeners[listener:getEvent()] = {}
  end

  table.insert(self._eventListeners[listener:getEvent()], listener)

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

  local _, listener = tableUtil.first(self._eventListeners[event], function(v)
    return (
      v:getEvent() == event and
      v:getHandler() == handler and
      v:isDefault() == default and
      v:isRunBefore() == before and
      v:getCancelHandler() == onCancel and
      v:isCapturing() == capture
    )
  end)

  return listener
end

--- Remove all defined event listeners.
-- @tparam[opt=false] boolean default whether to remove default listeners as well
function EventTarget:removeAllListeners(default)
  if default then
    self._eventListeners = {}

    return
  end

  for _, listeners in pairs(self._eventListeners) do
    for idx = #listeners, 1, -1 do
      if not listeners[idx]:isDefault() then
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
  event._phase = EventPhase.None

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
      event._phase = EventPhase.Capturing

      for i = #path, 1, -1 do
        event._target = path[i]
        event._defaultPrevented = false

        path[i]:_dispatchEvent(event)

        if event:isCanceled() then
          return true
        end
      end
    end

    if event.bubblable then
      event._phase = EventPhase.Bubbling

      for i = 1, #path, 1 do
        event._target = path[i]
        event._defaultPrevented = false

        path[i]:_dispatchEvent(event)

        if event:isCanceled() then
          return true
        end
      end
    end

    return false
  else
    -- flood dispatch
    local function dispatchCapture(element)
      event._target = element
      event._defaultPrevented = false

      element:_dispatchEvent(event)

      for _, child in ipairs(element:getChildEventTargets()) do
        if event:isCanceled() then
          return true
        end

        dispatchCapture(child)
      end
    end

    local function dispatchBubbling(element)
      event._target = element
      event._defaultPrevented = false

      local children = element:getChildEventTargets()

      for i = #children, 1, -1 do
        dispatchBubbling(children[i])

        if event:isCanceled() then
          return true
        end
      end

      element:_dispatchEvent(event)
    end

    if event.capturable then
      event._phase = EventPhase.Capturing

      if dispatchCapture(self) then
        return true
      end
    end

    if event.bubblable then
      event._phase = EventPhase.Bubbling

      if dispatchBubbling(self) then
        return true
      end
    end
  end
end

function EventTarget:_removeEventListener(listener)
  local removed = not not tableUtil.removeFirst(
    self._eventListeners[listener:getEvent()],
    listener
  )

  if removed and #self._eventListeners[listener:getEvent()] == 0 then
    self._eventListeners[listener:getEvent()] = nil
  end

  return removed
end

function EventTarget:_dispatchEvent(event)
  if not self._eventListeners[event.class] then
    return
  end

  local queue = {}
  local before, user, default = 1, 1, 1

  for _, listener in ipairs(self._eventListeners[event.class]) do
    if (event:getPhase() == EventPhase.Capturing and
          listener:isCapturing() or
        event:getPhase() == EventPhase.Bubbling and
          not listener:isCapturing()) then
      if not listener:isDefault() then
        table.insert(queue, user, listener)
        user = user + 1
        default = default + 1
      elseif not listener:isRunBefore() then
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
    if idx <= default and not event:isCanceled() and
        (idx > before and idx <= user or not event:isDefaultPrevented()) then
      -- run default-before (if not prevented), user, and default (if not
      -- prevented) listeners

      listener:getHandler()(self, event, listener)

      if idx <= before and listener:getCancelHandler() then
        -- if the default-before listener has an on-cancel callback, add it to
        -- the end of the queue again
        table.insert(queue, listener)
      end
    elseif event:isDefaultPrevented() and idx > default then
      -- if the default listeners are prevented, run on-cancel callbacks
      listener:getCancelHandler()(self, event, listener)
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
