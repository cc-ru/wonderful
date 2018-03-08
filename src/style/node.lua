local class = require("lua-objects")

local Node = class(nil, {name = "wonderful.style.node.Node"})

function Node:__new__(line, col, value)
  self.line = line
  self.col = col
  self.value = value
end

function Node:__tostring__()
  local result = "[Node " .. self.NAME

  if self.line then
    result = result .. ": L" .. self.line
    if self.col then
      result = result .. ":" .. self.col
    end
  end

  result = result .. " = "

  if self.value ~= nil then
    result = result .. tostring(self.value)
  else
    result = result .. "nil"
  end
  result = result .. "]"
  return result
end

local RootNode = class(Node, {name = "wonderful.style.node.RootNode"})

local ImportNode = class(Node, {name = "wonderful.style.node.ImportNode"})
local PathNode = class(Node, {name = "wonderful.style.node.PathNode"})

local NameNode = class(Node, {name = "wonderful.style.node.NameNode"})

function NameNode:__new__(line, col, path, name, isModule)
  self.line = line
  self.col = col
  self.path = path
  self.name = name
  self.module = isModule
end

local VarNode = class(Node, {name = "wonderful.style.node.VarNode"})

function VarNode:__new__(line, col, name, type, value, public)
  self.line = line
  self.col = col
  self.name = name
  self.type = type
  self.value = value
  self.public = public
end

local ValueNode = class(Node, {name = "wonderful.style.node.ValueNode"})

local TypeAliasNode = class(Node, {name = "wonderful.style.node.TypeAliasNode"})

function TypeAliasNode:__new__(line, col, name, type, public)
  self.line = line
  self.col = col
  self.name = name
  self.type = type
  self.public = public
end

local TypeRefNode = class(Node, {name = "wonderful.style.node.TypeRefNode"})
local ClassNameNode = class(Node, {name = "wonderful.style.node.ClassNameNode"})

local RuleNode = class(node, {name = "wonderful.style.node.RuleNode"})

function RuleNode:__new__(line, col, targets, properties, public)
  self.line = line
  self.col = col
  self.targets = targets
  self.properties = properties
  self.public = public
end

local TargetNode = class(Node, {name = "wonderful.style.node.TargetNode"})

function TargetNode:__new__(line, col, type, classes, selectors)
  self.line = line
  self.col = col
  self.type = type
  self.classes = classes
  self.selectors = selectors
end

local PropertyNode = class(Node, {name = "wonderful.style.node.PropertyNode"})

function PropertyNode:__new__(line, col, name, value, custom)
  self.line = line
  self.col = col
  self.name = name
  self.value = value
  self.custom = custom
end

local ClassNode = class(Node, {name = "wonderful.style.node.ClassNode"})

local SelectorNode = class(Node, {name = "wonderful.style.node.SelectorNode"})

function SelectorNode:__new__(line, col, name, value, custom)
  self.line = line
  self.col = col
  self.name = name
  self.value = value
  self.custom = custom
end

local AnyTypeNode = class(Node, {name = "wonderful.style.node.AnyTypeNode"})

function AnyTypeNode:__new__(line, col)
  self.line = line
  self.col = col
end

return {
  Node = Node,

  RootNode = RootNode,

  ImportNode = ImportNode,
  PathNode = PathNode,
  NameNode = NameNode,

  VarNode = VarNode,

  ValueNode = ValueNode,

  TypeAliasNode = TypeAliasNode,

  TypeRefNode = TypeRefNode,
  ClassNameNode = ClassNameNode,

  RuleNode = RuleNode,

  TargetNode = TargetNode,

  PropertyNode = PropertyNode,

  ClassNode = ClassNode,

  SelectorNode = SelectorNode,

  AnyTypeNode = AnyTypeNode,
}

