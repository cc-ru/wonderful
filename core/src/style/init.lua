--- The style engine.
-- "I wonder how it works" edition.
-- @see 204-Styles.md
-- @module wonderful.style

local buffer = require("buffer")

local class = require("lua-objects")

local textBuf = require("wonderful.style.buffer")
local interpreter = require("wonderful.style.interpreter")
local lexer = require("wonderful.style.lexer")
local parser = require("wonderful.style.parser")
local property = require("wonderful.style.property")

local Style = class(nil, {name = "wonderful.style.Style"})

function Style:__new__(args)
  self._stripped = true

  if args then
    if args.vars then
      self:addVars(args.vars)
    end

    if args.selectors then
      self:addSelectors(args.selectors)
    end

    if args.properties then
      self:addProperties(args.properties)
    end

    if args.types then
      self:addTypes(args.types)
    end

    if args.buffer then
      self:parseFromBuffer(args.buffer)
    elseif args.stream then
      self:parseFromStream(args.stream)
    elseif args.string then
      self:parseFromString(args.string)
    end
  end
end

function Style:addVars(vars)
  self.context:addVars(vars, true)
  return self
end

function Style:addSelectors(selectors)
  self.context:addSelectors(selectors, true)
  return self
end

function Style:addProperties(props)
  self.context:addProperties(props, true)
  return self
end

function Style:addTypes(types)
  self.context:addTypes(types, true)
  return self
end

function Style:parseFromString(str)
  local buf = textBuf.Buffer(str)
  return self:parseFromTextBuffer(buf)
end

function Style:parseFromStream(stream)
  local buf = textBuf.Buffer(stream)
  return self:parseFromTextBuffer(buf)
end

function Style:parseFromTextBuffer(buf)
  local tokStream = lexer.TokenStream(buf)
  local parser = parser.Parser(tokStream)
  self.context.ast = parser.ast

  self.context:interpret()

  self.rules = self.context.rules
  self._stripped = false

  return self
end

-- Removes the context.
-- A stripped style instance consumes less RAM, but cannot be imported.
function Style:stripContext()
  self.context = nil
  self._stripped = true
  return self
end

function Style:isContextStripped()
  return self._stripped
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
          result = prop
          resultRule = rule
        end
      end
    end
  end

  if result then
    return result
  end

  if component.parent then
    local prop = self:getProperty(component.parent, name)
    if prop.inherit then
      return prop
    end
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

function Style:_createContext()
  return interpreter.Context()
end

function Style.__getters:context()
  if not self._context then
    self._context = self:_createContext()
  end

  return self._context
end

local WonderfulStyle = class(Style, {name = "wonderful.style.WonderfulStyle"})

function WonderfulStyle:_createContext()
  local ctx = self:superCall("_createContext")

  ctx:addProperties({
    property.Color,
    property.BgColor
  }, false)

  return ctx
end

local PropRef = class(nil, {name = "wonderful.style.PropRef"})

function PropRef:__new__(element, name, default)
  self.style = nil
  self.value = nil
  self.element = element
  self.name = name
  self.default = default
end

function PropRef:get(default)
  if self.style ~= self.element.style then
    self:update()
  end

  if self.value then
    return self.value
  end

  if default then
    return default
  end

  if self.default then
    return self.default
  end
end

function PropRef:update()
  self.style = self.element.style
  self.value = self.style:getProperty(self.element, self.name)
end

--- @export
return {
  Style = Style,
  WonderfulStyle = WonderfulStyle,
  PropRef = PropRef,
}

