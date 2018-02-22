local class = require("lua-objects")

local textBuf = require("wonderful.style.buffer")
local lexer = require("wonderful.style.lexer")
local node = require("wonderful.style.node")
local parser = require("wonderful.style.parser")
local property = require("wonderful.style.property")
local sels = require("wonderful.style.selector")
local wtype = require("wonderful.style.type")
local tblUtil = require("wonderful.util.table")

local isin = tblUtil.isin

local function traverseSpec(spec, func)
  local function _traverse(target)
    func(target)
    if target.ascendant then
      _traverse(target.ascendant)
    end
    if target.parent then
      _traverse(target.parent)
    end
    if target.above then
      _traverse(target.above)
    end
    if target.dirAbove then
      _traverse(target.dirAbove)
    end
  end
  for k, v in pairs(spec) do
    _traverse(v)
  end
end

local Variable = class(nil, {name = "wonderful.style.interpreter.Context"})

function Variable:__new__(name, value, type, public, custom)
  self.name = name
  self.value = self.value
  self.type = type
  self.public = public
  self.custom = custom
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

function Rule:getSpecificity()
  local classSpec, selSpec = 0, 0, 0
  traverseSpec(self.spec, function(target)
    classSpec = classSpec + #target.classes
    selSpec = selSpec + #target.selectors
  end)
  return classSpec, selSpec
end

local TypeRef = class(nil, {name = "wonderful.style.interpreter.TypeRef"})

function TypeRef:__new__(name, public)
  self.name = name
  self.public = public
end

local Type = class(nil, {name = "wonderful.style.interpreter.Type"})

function Type:__new__(clazz, custom)
  self.class = clazz
  self.custom = custom
end

function Type:matches(instance)
  return instance:isa(self.class)
end

local NamedType = class(Type, {name = "wonderful.style.interpreter.NamedType"})

function NamedType:__new__(name, custom)
  self.name = name
  self.custom = custom
end

function NamedType:matches(instance)
  return instance.NAME == self.name
end

local AnyType = class(Type, {name = "wonderful.style.interpreter.AnyType"})

function AnyType:__new__(custom)
  self.custom = custom
end

function AnyType:matches()
  return true
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

-- TODO: sane error handling!
local Context = class(nil, {name = "wonderful.style.interpreter.Context"})

function Context:__new__(args)
  self.ast = args.parser.ast
  self.importPriority = 1
  self.vars = {}
  self.rules = {}
  self.types = {}
  self.selectors = {}
  self.properties = {}
  self:addVars(args.vars, true)
  self:addSelectors(args.selectors, true)
  self:addProperties(args.properties, true)
  self:addTypes(args.types, true)
end

function Context:addVars(vars, custom)
  for name, value in pairs(vars) do
    if type(name) ~= "string" or #name == 0 then
      error("Variable name must be a non-empty string")
    end
    if not value:isa(wtype.ExprType) then
      error("The value of user-specified variable '" .. name .. "' is not " ..
            "derived from ExprType.")
    end
    self.vars[name] = Variable(name, value, value.class, true,
                               custom)
  end
end

function Context:addSelectors(selectors, custom)
  for name, selector in pairs(selectors) do
    self.selectors[name] = {selector = selector, custom = custom}
  end
end

function Context:addProperties(properties, custom)
  for name, property in pairs(properties) do
    self.properties[name] = {property = property, custom = custom}
  end
end

function Context:addTypes(types, custom)
  for name, type in pairs(types) do
    type.custom = true
    self.types[name] = type
  end
end

function Context:getCustomVars()
  local result = {}
  for k, v in pairs(self.vars) do
    if v.custom then
      result[k] = v.value
    end
  end
end

function Context:getCustomSels()
  local result = {}
  for k, v in pairs(self.selectors) do
    if v.custom then
      result[k] = v.value
    end
  end
end

function Context:getCustomProps()
  local result = {}
  for k, v in pairs(self.properties) do
    if v.custom then
      result[k] = v.value
    end
  end
end

function Context:getCustomTypes()
  local result = {}
  for k, v in pairs(self.types) do
    if v.custom then
      result[k] = v.class
    end
  end
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
  self:evalVars()
  self:processRules()
end

function Context:import(stmt)
  if stmt.value:isa(node.PathNode) then
    -- import "path.wsf";
    local file = self:tryOpenFile(stmt.value.value)
    local buf = textBuf.Buffer(file)
    local tokStream = lexer.TokenStream(buf)
    local parser = parser.Parser(tokStream)
    local ctx = Context({
      parser = parser,
      vars = self:getCustomVars(),
      selectors = self:getCustomSels(),
      properties = self:getCustomProps(),
      types = self:getCustomTypes()
    })
    ctx:interpret()
    self:merge(ctx)
  elseif stmt.value:isa(node.NameNode) or stmt.value:isa(node.TypeRefNode) then
    -- import [module:name];
    -- import @Type;
    local ref = TypeRef(stmt.value)
    local ctx = self:resolveType(ref)

    -- TODO: support wonderful.style.Style, too
    if not ctx:isa(Context) then
      error("Imported name must be a wonderful.style.interpreter:Context")
    end

    self:merge(ctx)
  end
end

function Context:tryOpenFile(path)
  -- TODO: it's a good idea to use fs.exists before io.opening
  local f, reason = io.open(path)
  if not f then
    error("Could not open the file at " .. path .. ": " .. reason)
  end
  return f
end

function Context:merge(ctx)
  for k, v in pairs(ctx.vars) do
    if v.public and not v.custom then
      v.priority = self.importPriority
      self.vars[k] = v
    end
  end

  for k, v in pairs(ctx.types) do
    if v.public and not v.custom then
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

  self.importPriority = self.importPriority + priority + (huge and 1 or 0) + 1
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
    props[v.name] = Property(v.name, v.value, v.custom)
  end
  table.insert(self.rules, Rule(math.huge, Spec(stmt.targets), props,
                                stmt.line, stmt.col, stmt.public))
end

function Context:resolveTypeRefs()
  for k in pairs(self.types) do
    self.types[k] = self:resolveType(self.types[k])
  end

  -- Now find any references
  for k, v in pairs(self.vars) do
    if v.type then
      v.type = self:resolveType(v.type)
    end
  end

  for _, rule in pairs(self.rules) do
    traverseSpec(rule.spec, function(target)
      if target.type then
        target.type = self:resolveType(target.type)
      end
    end)
  end
end

-- Resolves TypeRef to Type
function Context:resolveType(typeRef)
  if typeRef:isa(Type) then
    return typeRef
  end

  local name = typeRef.name
  if name:isa(node.TypeRefNode) then
    local referenced = self.types[name.value]
    self.types[name.value] = self:resolveType(referenced)
    return self.types[name.value]
  elseif name:isa(node.NameNode) then
    if name.module then
      return self:importName(name.path, name.name)
    else
      return self:loadName(name.path, name.name)
    end
  elseif name:isa(node.ClassNameNode) then
    return NamedType(name.value, false)
  elseif name:isa(node.AnyTypeNode) then
    return AnyType(false)
  end
end

function Context:processRules()
  for _, rule in pairs(self.rules) do
    -- Selectors
    traverseSpec(rule.spec, function(target)
      local selector = self.selectors[target.selector.name]
      if not selector or selector.custom ~= target.selector.custom then
        error("Unknown selector: " .. (target.selector.custom and "~" or "") ..
              target.selector.name)
      end
      target.selector = selector.selector(target.selector.value)
    end)

    -- Properties
    for k, v in pairs(rule.props) do
      local prop = self.properties[v.name]
      if not prop or prop.custom ~= v.custom then
        error("Unknown property: " .. (v.custom and "~" or "") .. v.name)
      end
      rule.props[k] = prop.property(v.value)
    end

    -- Classes
    traverseSpec(rule.spec, function(target)
      for k, v in pairs(target.classes) do
        target.classes[k] = v.value
      end
    end)
  end
end

function Context:evalVars()
  for name, var in pairs(self.vars) do
    local exprType = var.type or self:guessType(var.value)
    if not exprType then
      error("Variable " .. name .. " has no associated type")
    end
    if not exprType:isa(wtype.ExprType) then
      error("The specified type of variable " .. name .. " isn't derived " ..
            "from ExprType.")
    end
    var.value = exprType:parse(var.value)
  end
end

function Context:importName(modPath, name)
  -- TODO: error handling!
  return require(modPath)[name]
end

function Context:loadName(path, name)
  -- TODO: error handling!
  return load(path, "t", _G)[name]
end

function Context:guessType(value)
  -- TODO: add guessers
end

