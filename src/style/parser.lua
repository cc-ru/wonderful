local class = require("lua-objects")

local node = require("wonderful.style.node")
local lexer = require("wonderful.style.lexer")

local Parser = class(nil, {name = "wonderful.style.parser.Parser"})

Parser.rulePuncs = "*.:"

function Parser:__new__(stream)
  self.stream = stream

  local stmts = {}
  while not self.stream:eof() do
    table.insert(stmts, self:parseStmt())
  end
  self.ast = node.RootNode(1, 1, stmts)
end

function Parser:error(token, ...)
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

function Parser:parseStmt(skipSep)
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
    if self.rulePuncs:find(token.value, 1, true) then
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
  if not (token:isa(lexer.OpToken) and token.value == "=") then
    self:error(token, "Expected ", lexer.OpToken(token.line, token.col, "="))
  end
  local value = self:parseExpr(varType)
  return node.VarNode(varToken.line, varToken.col, name, varType, value)
end

function self:parseRule(public)
  local targets = self:parseDelimited(nil, ",", "{", self.parseSpec)
  local props = self:parseDelimited("{", ";", "}", self.parseProp)
end

function self:parseDelimited(startp, delimiter, endp, parser)
  if startp then
    self:skip(lexer.PuncToken, startp)
  end

  local result = {}
  while true do
    table.insert(result, parser(self))
    local token = self.stream:peek()

    if token and token:isa(lexer.PuncToken) then
      if token.value == endp then
        break
      end
    end

    if not token then
      self:error(nil, "Delimited section not closed")
    end

    self:skip(lexer.PuncToken, delimiter)
  end

  return result
end

function self:parseSpec()
  local target = self:parseTarget()

  local processed = false
  repeat
    processed = false
    local token = self.stream:peek()
    if token:isa(lexer.OpToken) then
      if token.value == ">>" or token.value == ">" or
          token.value == "~>>" or token.value == "~>" then
        self.stream:next()
        local right = self:parseTarget()

        if token.value == ">>" then
          right.ascendant = target
        elseif token.value == ">" then
          right.parent = target
        elseif token.value == "~>>" then
          right.above = target
        elseif token.value == "~>" then
          right.dirAbove = target
        end

        target = right
        processed = true
      end
    end
  until not processed

  return target
end

function self:parseProp()
  local token = self.stream:peek()
  local custom = false
  if token:isa(lexer.PuncToken) and token.value == "~" then
    custom = true
  end

  local name = self:parseIdent()
  self:skip(lexer.PuncToken, ":")

  local value = self:parseExpr()

  return node.PropertyNode(token.line, token.col, name, value, custom)
end

function self:parseName(classNameAllowed)
  error("unimplemented")
end

function self:parsePath()
  error("unimplemented")
end

function self:parseExpr(varType)
  error("unimplemeted")
end

function self:parseTarget()
  error("unimplemented")
end

