local buffer = require("buffer")

local class = require("lua-objects")

local interpreter = require("wonderful.style.interpreter")
local lexer = require("wonderful.style.lexer")
local parser = require("wonderful.style.parser")
local textBuf = require("wonderful.style.buffer")

local Style = class(nil, {name = "wonderful.style.Style"})

function Style:__new__(context)
  self.rules = context.rules
end

function Style:fromStream(istream, vars, selectors, properties, types)
  local buf = textBuf.Buffer(istream)
  return self:fromBuffer(buf)
end

function Style:fromString(str, vars, selectors, properties, types)
  local buf = textBuf.Buffer(str)
  return self:fromBuffer(buf)
end

function Style:fromBuffer(buf, vars, selectors, properties, types)
  local tokStream = lexer.TokenStream(buf)
  local parser = parser.Parser(tokStream)
  local ctx = interpreter.Context({
    parser = parser,
    vars = vars,
    selectors = selectors,
    properties = properties,
    types = types
  })
  ctx:interpret()
  return self(ctx), ctx
end

return {
  Style = Style
}

