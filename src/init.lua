local component = require("component")
local event = require("event")

local class = require("lua-objects")

local document = require("wonderful.element.document")
local render = require("wonderful.render")
local signal = require("wonderful.signal")

local Wonderful = class(nil, {name = "wonderful.Wonderful"})

function Wonderful:__new__()
  self.renderer = render.Renderer()
  self.documents = {}
  self.signals = {}
  self.running = false
  self:updateKeyboards()

  self:addSignal("touch", signal.Touch)
  self:addSignal("drag", signal.Drag)
  self:addSignal("drop", signal.Drop)
  self:addSignal("scroll", signal.Scroll)

  self:addSignal("key_down", signal.KeyDown)
  self:addSignal("key_up", signal.KeyUp)
  self:addSignal("clipboard", signal.Clipboard)
end

function Wonderful:updateKeyboards()
  self.keyboards = {}

  for screen in component.list("screen", true) do
    for _, keyboard in ipairs(component.invoke(screen, "getKeyboards")) do
      self.keyboards[keyboard] = screen
    end
  end
end

function Wonderful:addDocument(args)
  local args = args or {}

  if args.x and args.y and args.w and args.h then
    args.box = Box(args.x, args.y, args.w, args.h)
  end

  local target = self.renderer:newTarget {
    box = args.box,
    screen = args.screen
  }

  local document = document.Document {
    style = args.style,
    renderTarget = target
  }

  table.insert(self.documents, document)
  return document
end

do
  local function rStackingContext(root)
    local buf = root.renderTarget.newBuffer

    for _, el in root.stackingContext.iter do
      if el.isLeaf or el.stackingContext == root.stackingContext then
        if el.calculatedBox then
          local view = buf:view(el.calculatedBox:unpack())

          if view then
            el:render(view)
          end
        end
      else
        rStackingContext(el)
      end
    end
  end

  function Wonderful:render()

    for _, document in ipairs(self.documents) do
      rStackingContext(document)
    end

    for _, target in ipairs(self.renderer.targets) do
      target:flush()
    end
  end
end

do
  local function hStackingContext(root)
    for _, el in root.stackingContext.iterRev do
      if el.isLeaf or el.stackingContext == root.stackingContext then
        if el.calculatedBox:has(x, y) then
          return el
        end
      else
        local hit = hStackingContext(el)

        if hit then
          return hit
        end
      end
    end
  end

  function Wonderful:hit(screen, x, y)
    for _, document in ipairs(self.documents) do
      if document.renderTarget.screen == screen and
         document.renderTarget.box:has(x, y) then

        local hit = hStackingContext(document, x, y)

        if hit then
          return hit
        end
      end
    end
  end
end

function Wonderful:addSignal(name, cls)
  self.signals[name] = cls
end

function Wonderful:run()
  self.running = true
  while self.running do
    local pulled = {event.pull()}
    local name = table.remove(pulled, 1)

    if name and self.signals[name] then
      local inst = self.signals[name](table.unpack(pulled))

      if signal.SCREEN_SIGNALS[name] then
        local hit = self:hit(inst.screen, inst.x, inst.y)

        if hit then
          hit:dispatchEvent(inst)
        end
      elseif signal.KEYBOARD_SIGNALS[name] then
        local screen = self.keyboards[screen]

        if screen then
          for _, document in ipairs(self.documents) do
            if document.renderTarget.screen == screen then
              document:dispatchEvent(inst)
            end
          end
        end
      else
        for _, document in ipairs(self.documents) do
          document:dispatchEvent(inst)
        end
      end

      self:render()
    end
  end
end

function Wonderful:stop()
  self.running = false
end

return {
  Wonderful = Wonderful,
  Document = document.Document,
  Renderer = render.Renderer,
  RenderTarget = render.RenderTarget
}

