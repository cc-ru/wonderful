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

function Context:parseStmt(skipSep)
  skipSep = skipSep == nil and true

  local token = self.stream:peek()

  local public = false
  if token:isa(lexer.KwToken) and token.value == "pub" then
    public = true
    self.stream:next()
    token = self.stream:peek()
  end

  local stmt
  if token:isa(lexer.KwToken) then
    if token.value == "import" and not public then
      stmt = self:parseImport()
    elseif token.value == "type" then
      stmt = self:parseTypeAlias(public)
    else
      self:error(token, "Bad keyword")
    end
  elseif token:isa(lexer.IdentToken) then
    stmt = self:parseVar(public)
  elseif token:isa(lexer.NameToken) then
    stmt = self:parseRule(public)
  elseif token:isa(lexer.PuncToken) then
    if token.value == "@" then
      -- type ref
      stmt = self:parseRule(public)
    elseif token.value == "." then
      -- class
      stmt = self:parseRule(public)
    end
  end

  if not stmt then
    self:error(token, "Unknown token")
  end

  if skipSep then
    self:skip(lexer.PuncToken, ";")
  end
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

function self:parseVar(public)
  local varToken = self.stream:peek()
  local name = self:parseIdent()
  local token = self.stream:next()
  local varType = nil
  if token:isa(lexer.PuncToken) and token.value == ":" then
    -- Type specifier
    varType = self:parseName(false)
    token = self.stream:next()
  end
  if not (token:isa(lexer.PuncToken) and token.value == "=") then
    self:error(token, "Expected ", lexer.PuncToken(token.line, token.col, "="))
  end
  local value = self:parseExpr(varType)
  return node.VarNode(varToken.line, varToken.col, name, varType, value)
end
