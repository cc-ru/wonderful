local class = require("lua-objects")

local lexer = require("wonderful.style.lexer")
local parser = require("wonderful.style.parser")
local textBuf = require("wonderful.style.buffer")
local node = require("wonderful.style.node")
local util = require("wonderful.util")

local isin = util.isin

local Variable = class(nil, {name = "wonderful.style.interpreter.Context"})

function Variable:__new__(name, value, type, public)
  self.name = name
  self.priority = priority
  self.value = self.value
  self.type = type
  self.public = public
end

local Rule = class(nil, {name = "wonderful.style.interpreter.Rule"})

function Rule:__new__(priority, spec, properties, line, col, public)
  self.priority = priority
  self.spec = spec
  self.props = properties
  self.public = public
  self.line = line
  self.col = col
end

function Rule:matches(component)
  return self.spec:matches(component)
end

local TypeRef = class(nil, {name = "wonderful.style.interpreter.TypeRef"})

function TypeRef:__new__(name)
  self.name = name
end

local Spec = class(nil, {name = "wonderful.style.interpreter.Spec"})

function Spec:__new__(targets)
  self.targets = targets
end

function Spec:matches(component)
  for _, target in pairs(self.targets) do
    if self:targetMatches(target, component) then
      return true
    end
  end
end

function Spec:targetMatches(target, component)
  -- Check type
  if target.type then
    if not target:matches(component) then
      return false
    end
  end

  -- Check classes
  for k, v in pairs(target.classes) do
    -- TODO: index the actual classes property
    if not isin(v, component.classes) then
      return false
    end
  end

  -- Check selectors
  for k, v in pairs(target.selectors) do
    if not v:matches(component) then
      return false
    end
  end

  -- Check ascendants
  if target.ascendant then
    local ascendant = component
    while true do
      ascendant = ascendant.parent
      if not ascendant then
        return false
      end
      if self:targetMatches(target.ascendant, ascendant) then
        break
      end
    end
  end

  -- Check parent
  if target.parent then
    if not component.parent then
      return false
    end
    if not self:targetMatches(target.parent, component.parent) then
      return false
    end
  end

  -- Check siblings above
  if target.above then
    local parent = component.parent
    if not parent then
      return false
    end
    for i, v in ipairs(parent.children) do
      if v == component then
        return false
      end
      if self:targetMatches(target.above, v) then
        break
      end
    end
  end

  -- Check direct sibling above
  if target.dirAbove then
    local parent = component.parent
    if not parent then
      return false
    end
    local _, pos = isin(component, parent.children)
    if pos == 1 then
      return false
    end
    if not self:targetMatches(target.dirAbove, parent.children[pos - 1]) then
      return false
    end
  end

  return true
end

local Context = class(nil, {name = "wonderful.style.interpreter.Context"})

function Context:__new__(parser)
  self.ast = parser.ast
  self.importPriority = 1
  self.vars = {}
  self.rules = {}
  self.types = {}
  self:interpret()
end

function Context:interpret()
  for _, stmt in ipairs(self.ast.value) do
    if stmt:isa(node.ImportNode) then
      self:import(stmt)
    elseif stmt:isa(node.VarNode) then
      self:setVar(stmt)
    elseif stmt:isa(node.TypeAliasNode) then
      self:setType(stmt)
    elseif stmt:isa(node.RuleNode) then
      self:addRule(stmt)
    end
  end

  self:resolveTypeRefs()
  self:resolveCustomRules()
  self:packValues()
  self:evalExpressions()
end

function Context:import(stmt)
  if stmt.value:isa(node.PathNode) then
    local file = self:openFile(stmt.value, stmt.value.value)
    local buf = textBuf(file)
    local tokStream = lexer.TokenStream(buf)
    local parser = parser.Parser(tokStream)
    local ctx = Context(parser)
    self:merge(ctx)
  end
end

function Context:tryOpenFile(stmt, path)
  error("unimplemented")
end

function Context:merge(ctx)
  for k, v in pairs(ctx.vars) do
    if v.public then
      self.vars[k] = v
    end
  end

  for k, v in pairs(ctx.types) do
    if v.public then
      self.types[k] = v
    end
  end

  local huge = false
  local priority = 0
  for k, v in pairs(ctx.rules) do
    if v.priority == math.huge then
      huge = true
    else
      priority = math.max(priority, v.priority)
    end
  end

  priority = self.importPriority + priority

  for k, v in pairs(ctx.rules) do
    if v.public then
      local p = v.priority
      if p == math.huge then
        p = priority
      else
        p = v.priority + self.importPriority - 1
      end
      table.insert(self.rules,
                   Rule(priority, v.spec, v.props, v.line, v.col, true))
    end
  end

  self.importPriority = self.importPriority + priority + (huge and 1 or 0)
end

function Context:setType(stmt)
  self.types[stmt.name] = TypeRef(stmt.type, stmt.public)
end

function Context:setVar(stmt)
  self.vars[stmt.name] = Variable(stmt.name, stmt.value,
                                  TypeRef(stmt.type), stmt.public)
end

function Context:addRule(stmt)
  local props = {}
  for k, v in ipairs(stmt.properties) do
    table.insert(props, Property(v.name, v.value, v.custom))
  end
  table.insert(self.rules, Rule(math.huge, Spec(stmt.targets), props,
                                stmt.line, stmt.col, stmt.public))
end

function Context:resolveTypeRefs()
  error("unimplemented")
end

function Context:resolveCustomRules()
  error("unimplemented")
end

function Context:packValues()
  error("unimplemented")
end

function Context:evalExpressions()
  error("unimplemented")
end

