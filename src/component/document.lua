local class = require("lua-objects")

local element = require("wonderful.component.element")
local StackingContext = require("wonderful.component.stack").StackingContext
local style = require("wonderful.style")
local render = require("wonderful.render")

local Document = class(
  element.Element,
  {name = "wonderful.component.document.Document"}
)

function Document:__new__(args)
  self:superCall(element.Element, "__new__")

  if args.style and args.style:isa(style.Style) then
    self.globalStyle = args.style
  elseif type(args.style) == "table" and args.style.read then
    self.globalStyle = style.Style:fromBuffer(args.style)
  elseif type(args.style) == "string" then
    self.globalStyle = style.Style:fromString(args.style)
  else
    self.globalStyle = style.Style()
  end

  if args.renderTarget and args.renderTarget:isa(render.RenderTarget) then
    self.globalRenderTarget = args.renderTarget
    self.globalRenderer = self.globalRenderTarget.renderer
  else
    self.globalRenderer = render.Renderer()
    self.globalRenderTarget = self.globalRenderer:newTarget()
  end

  self.rootStackingContext = StackingContext()
  self.rootStackingContext:insertStatic(1, self)

  self.calculatedBox = self.globalRenderTarget.box
end

function Document.__getters:stackingContext()
  return self.rootStackingContext
end

return {
  Document = Document
}

