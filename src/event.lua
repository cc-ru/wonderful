local class = require("lua-objects")

local util = require("wonderful.util")

local EventPhase = {
  None = 0,
  Capturing = 1,
  AtTarget = 2,
  Bubbling = 3
}

local Event = class(nil, {name = "wonderful.event.Event"})

function Event:__new__(name, payload)
  self.name = name
  self.payload = payload or {}

  self.cancelled = false
  self.propagationStopped = false
  self.defaultPrevented = false

  self.phase = EventPhase.None
end

function Event:cancel()
  self.cancelled = true
end

function Event:stopPropagation()
  self.propagationStopped = true
end

function Event:preventDefault()
  self.defaultPrevented = true
end

local EventTarget = class(nil, {name = "wonderful.event.EventTarget"})

function EventTarget:__new__()
  self.listeners = {}
  self.defaultListeners = {}
end

function EventTarget:addEventListener(cls, handler, options)
  if not self.listeners[cls] then
    self.listeners[cls] = {}
  end

  local listener = util.shallowcopy(options or {})
  listener.handler = handler

  table.insert(self.listeners[cls], listener)
end

function EventTarget:removeEventListener(cls, handler, options)
  if not self.listeners[cls] then return end

  local query = util.shallowcopy(options or {})
  query.handler = query

  for i, listener in ipairs(self.listeners[cls]) do
    if util.shalloweq(listener, query) then
      table.remove(self.listeners, i)
      return true
    end
  end

  return
end

function EventTarget:setDefaultEventListener(cls, handler, options)
  local listener = util.shallowcopy(options or {})
  listener.handler = handler

  self.defaultListeners[cls] = listener
end

function EventTarget:removeDefaultEventListener(cls)
  self.defaultListeners[cls] = nil
end

function EventTarget:getCapturingParent()
  error("unimplemented abstract method EventTarget:getCapturingParent")
end

function EventTarget:getBubblingChildren()
  error("unimplemented abstract method EventTarget:getBubblingChildren")
end

function EventTarget:dispatchEvent(event)
  for i, listener in ipairs(self.listeners[event.class]) do
    self:_handleEvent(listener, event)

    if listener.once then
      table.remove(self.listeners[event.class], i)
    end

    if event.cancelled then break end
  end

  if not event.defaultPrevented and self.defaultListeners[event.class] then
    self:_handleEvent(self.defaultListeners[event.class], event)
  end
end

function EventTarget:_handleEvent(listener, event)
  event.target = self

  if listener.capture then
    event.phase = EventPhase.Capturing

    local parent = self.etCapturingParent()

    if parent then
      event.currentTarget = parent
      parent:dispatchEvent(event)
    end
  end

  event.phase = EventPhase.AtTarget
  event.currentTarget = self
  listener.handler(event)
  
  event.phase = EventPhase.Bubbling

  for _, child in ipairs(self:etBubblingChildren()) do
    if event.propagationStopped then break end

    event.currentTarget = child
    child:dispatchEvent(event)
  end
end

return {
  EventPhase = EventPhase,
  Event = Event,
  EventTarget = EventTarget
}

