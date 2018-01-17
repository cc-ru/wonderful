local class = require("lua-objects")

local Node = class(nil, {name = "wonderful.style.node.Node"})

function Node:__new__(line, col, value)
  self.line = line
  self.col = col
  self.value = value
end

local ImportNode = class(Node, {name = "wonderful.style.node.ImportNode"})
local PathNode = class(Node, {name = "wonderful.style.node.PathNode"})
local NameNode = class(Node, {name = "wonderful.style.node.NameNode"})

local VarNode = class(Node, {name = "wonderful.style.node.VarNode"})

function VarNode:__new__(line, col, name, type, value, public)
  self.line = line
  self.col = col
  self.name = name
  self.type = type
  self.value = value
  self.public = public
end

local ExprNode = class(Node, {name = "wonderful.style.node.ExprNode"})
local VarRefNode = class(Node, {name = "wonderful.style.node.VarRefNode"})

local TypeAliasNode = class(Node, {name = "wonderful.style.node.TypeAliasNode"})

function TypeAliasNode:__new__(line, col, name, type)
  self.line = line
  self.col = col
  self.name = name
  self.type = type
end

local TypeRefNode = class(Node, {name = "wonderful.style.node.TypeRefNode"})
local ClassNameNode = class(Node, {name = "wonderful.style.node.ClassNameNode"})

local RuleNode = class(node, {name = "wonderful.style.node.RuleNode"})

function RuleNode:__new__(line, col, type, classes, selectors, properties)
  self.line = line
  self.col = col
  self.type = type
  self.classes = classes
  self.selectors = selectors
  self.properties = properties
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

return {
  Node = Node,

  ImportNode = ImportNode,
  PathNode = PathNode,
  NameNode = NameNode,

  VarNode = VarNode,

  ExprNode = ExprNode,
  VarRefNode = VarRefNode,

  TypeAliasNode = TypeAliasNode,

  TypeRefNode = TypeRefNode,
  ClassNameNode = ClassNameNode,

  RuleNode = RuleNode,

  PropertyNode = PropertyNode,

  ClassNode = ClassNode,

  SelectorNode = SelectorNode,
}
