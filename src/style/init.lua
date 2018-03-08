local buffer = require("buffer")

local class = require("lua-objects")

local textBuf = require("wonderful.style.buffer")
local interpreter = require("wonderful.style.interpreter")
local lexer = require("wonderful.style.lexer")
local parser = require("wonderful.style.parser")

local Style = class(nil, {name = "wonderful.style.Style"})

function Style:__new__(context)
  if context then
    self.rules = context.rules
  else
    self.rules = {}
  end
end

function Style:fromStream(istream, vars, selectors, properties, types)
  local buf = textBuf.Buffer(istream)
  return self:fromBuffer(buf, vars, selectors, properties, types)
end

function Style:fromString(str, vars, selectors, properties, types)
  local buf = textBuf.Buffer(str)
  return self:fromBuffer(buf, vars, selector, properties, types)
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

function Style:getProperty(component, name)
  local result, resultRule
  for k, rule in pairs(self.rules) do
    if rule:matches(component) then
      local prop = rule.props[name]
      if prop then
        local replace = false
        if not result then
          replace = true
        elseif self:_chooseRule(rule, resultRule) == rule then
          replace = true
        end
        if replace then
          result = prop.value
          resultRule = rule
        end
      end
    end
  end
  if result then
    return result
  end
  if component.parent then
    -- TODO: don't default-inherit properties unless explicitly set.
    return self:getProperty(component.parent, name)
  end
end

function Style:_chooseRule(r1, r2)
  -- Choose more specific one
  local c1, s1 = r1:getSpecificity()
  local c2, s2 = r2:getSpecificity()
  if c1 > c2 or c1 == c2 and s1 > s2 then
    return r1
  elseif c1 < c2 or c1 == c2 and s1 < s2 then
    return r2
  end

  -- Prioritize later imports
  if r1.priority > r1.priority then
    return r1
  elseif r2.priority > r2.priority then
    return r2
  end

  -- Prioritize later definitions in file
  if r1.line > r2.line then
    return r1
  elseif r1.line < r2.line then
    return r2
  end
  if r1.col > r2.col then
    return r1
  elseif r1.col < r2.col then
    return r2
  else
    error("Impossible situation: two rules defined at the same position")
  end
end

return {
  Style = Style,
}

