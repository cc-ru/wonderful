local class = require("lua-objects")

local node = require("wonderful.style.node")
local lexer = require("wonderful.style.lexer")

local Context = class(nil, {name = "wonderful.style.parser.Context"})

function Context:__new__(stream)
  self.stream = stream

  local stmts = {}
  while not self.stream:eof() do
    table.insert(stmts, self:parseStmt())
  end
  self.ast = node.RootNode(1, 1, stmts)
end

function Context:error(token, ...)
  local msg = ""
  for _, v in ipairs({...}) do
    if type(v) == "string" then
      msg = msg .. v
    elseif v:isa(lexer.Token) then
      msg = msg .. "[" .. v.NAME .. " '" .. tostring(v.value) .. "']"
    end
  end
  if token then
    local line, col = token.line, token.col
    local prefix = "L" .. line .. ":" .. col .. ": "
    msg = (prefix .. "[" .. token.NAME .. " '" .. tostring(token.value) ..
           "'] " .. msg)
    local lineMsg = prefix .. self.stream.buf:getLine(line)
    io.stderr:write(lineMsg)
    io.stderr:write((" "):rep(ulen(lineMsg) - 1) .. "^")
  end
  error(msg)
end

function Context:parseStmt()
  local token = self.stream:peek()

  local stmt
  if token:isa(lexer.KwToken) then
    if token.value == "import" then
      stmt = self:parseImport()
    elseif token.value == "type" then
      stmt = self:parseTypeAlias(false)
    elseif token.value == "pub" then
      stmt = self:parsePub()
    else
      self:error(token, "Unknown keyword")
    end
  elseif token:isa(lexer.IdentToken) then
    stmt = self:parseVar(false)
  elseif token:isa(lexer.NameToken) then
    stmt = self:parseRule(false)
  elseif token:isa(lexer.PuncToken) then
    if token.value == "@" then
      -- type ref
      stmt = self:parseRule()
    elseif token.value == "." then
      -- class
      stmt = self:parseRule()
    end
  end

  if not stmt then
    self:error(token, "Unknown token")
  end

  self:skip(lexer.PuncToken, ";")
  return stmt
end

function self:skip(tokenType, value)
  local token = self.stream:next()
  self.current = token
  if token:isa(tokenType) then
    if value ~= nil and token.value == value then
      return true
    end
  end
  self:error(token, "Expected ", tokenType(token.line, token.col, value))
end

function self:parseImport()
  local token = self.stream:next()
  local nameToken = self.stream:peek()
  local name
  if nameToken:isa(lexer.NameToken) then
    name = self:parseName(false)
  elseif nameToken:isa(lexer.StrToken) then
    name = self:parsePath()
  else
    self:error(token, "Expected style object name or path")
  end
  return node.ImportNode(token.line, token.col, name)
end

function self:parseTypeAlias(public)
  local token = self.stream:next()
  local alias = self:parseIdent()
  self:skip(lexer.OpToken, "=")
  local name = self:parseName(true)
  return node.TypeAliasNode(token.line, token.col, alias, name, false)
end

function self:parseIdent()
  local token = self.stream:next()
  if not token:isa(lexer.IdentToken) then
    self:error(token, "Expected identifier")
  end
  return token.value
end
