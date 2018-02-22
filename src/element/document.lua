local class = require("lua-objects")

local element = require("wonderful.element")
local display = require("wonderful.display")
local style = require("wonderful.style")

local StackingContext = require("wonderful.element.stack").StackingContext

local Document = class(
  element.Element,
  {name = "wonderful.element.document.Document"}
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

  self.globalDisplay = args.display

  self.rootStackingContext = StackingContext()
  self.rootStackingContext:insertStatic(1, self)

  self.calculatedBox = self.globalDisplay.box
end

function Document.__getters:stackingContext()
  return self.rootStackingContext
end

return {
  Document = Document
}

