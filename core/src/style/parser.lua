--- The style parser.
-- @module wonderful.style.parser

local unicode = require("unicode")

local class = require("lua-objects")

local lexer = require("wonderful.style.lexer")
local node = require("wonderful.style.node")

local ulen = unicode.len

local Parser = class(nil, {name = "wonderful.style.parser.Parser"})

Parser.rulePuncs = "*.:"

function Parser:__new__(stream)
  self.stream = stream

  local stmts = {}
  while not self.stream:eof() do
    local token, reason = self:parseStmt()

    if not token and reason == "eof" then
      break
    elseif not token then
      self:error("cur", "Could not parse statement: " ..
                        (reason or "unknown reason"))
    end

    table.insert(stmts, token)
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
    local line, col
    if token == "cur" then
      local cur = self.stream:peek()
      if cur then
        line = cur.line
        col = cur.col
      else
        -- EOF
        line = #self.stream.buf.lines + 1
        col = 1
      end
    else
      line, col = token.line, token.col
    end
    local prefix = "L" .. line .. ":" .. col .. ": "
    if token ~= "cur" then
      msg = (prefix .. "[" .. token.NAME .. " '" .. tostring(token.value) ..
             "'] " .. msg)
    end
    local lineMsg = prefix .. (self.stream.buf:getLine(line) or "\n")
    io.stderr:write(lineMsg)
    io.stderr:write((" "):rep(ulen(lineMsg) - 1) .. "^\n")
  end
  error(msg, 2)
end

function Parser:parseStmt(skipSep)
  skipSep = skipSep == nil and true

  local token, reason = self.stream:peek()

  if self.stream:eof() then
    return nil, "eof"
  elseif not token then
    return nil, reason
  end

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
  elseif token:isa(lexer.ClassNameToken) then
    stmt = self:parseRule(public)
  elseif token:isa(lexer.TypeRefToken) then
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

function Parser:skip(tokenType, value)
  local token, reason = self.stream:next()

  if self.stream:eof() then
    self:error("cur", "EOF eached, expected token ",
               tokenType(nil, nil, value))
  end

  self.current = token

  if token:isa(tokenType) then
    if value ~= nil and token.value == value then
      return true
    end
  end
  self:error(token, "Expected token ", tokenType(token.line, token.col, value))
end

function Parser:parseImport()
  local token = self.stream:next()
  if not token:isa(lexer.KwToken) or token.value ~= "import" then
    self:error(token, "Import statement expected")
  end
  local nameToken = self.stream:peek()
  local name
  if nameToken:isa(lexer.NameToken) or nameToken:isa(lexer.TypeRefToken) then
    name = self:parseName(false)
  elseif nameToken:isa(lexer.StrToken) then
    name = self:parsePath()
  else
    self:error(token, "Expected a style object name or path")
  end
  return node.ImportNode(token.line, token.col, name)
end

function Parser:parseTypeAlias(public)
  local token = self.stream:next()
  if not token:isa(lexer.KwToken) or token.value ~= "type" then
    self:error(token, "Type alias statement expected")
  end
  local alias = self:parseIdent()
  self:skip(lexer.OpToken, "=")
  local name = self:parseName(true)
  return node.TypeAliasNode(token.line, token.col, alias, name, false)
end

function Parser:parseIdent()
  local token = self.stream:next()
  if not token:isa(lexer.IdentToken) then
    self:error(token, "Expected identifier")
  end
  return token.value
end

function Parser:parseVar(public)
  local varToken = self.stream:peek()
  local name = self:parseIdent()
  local token = self.stream:next()

  if not (token:isa(lexer.OpToken) and token.value == "=") then
    self:error(token, "Expected ", lexer.OpToken(token.line, token.col, "="))
  end

  local value = self:parseExpr(lexer.PuncToken, ";")

  return node.VarNode(varToken.line, varToken.col, name, value)
end

function Parser:parseRule(public)
  local token = self.stream:peek()
  local targets = self:parseDelimited(nil, ",", "{", self.parseSpec)
  local props = self:parseDelimited("{", ";", "}", self.parseProp)
  -- skip the PuncToken("}")
  self.stream:next()
  return node.RuleNode(token.line, token.col, targets, props, public)
end

function Parser:parseDelimited(startp, delimiter, endp, parser)
  if startp then
    self:skip(lexer.PuncToken, startp)
  end

  local function checkEnd()
    local token = self.stream:peek()

    if token and token:isa(lexer.PuncToken) then
      if token.value == endp then
        return true
      end
    end

    if not token then
      self:error("cur", "Delimited section not closed")
    end

    return false
  end

  local result = {}

  if not checkEnd() then
    while true do
      if checkEnd() then
        break
      end

      table.insert(result, parser(self))

      if checkEnd() then
        break
      end

      self:skip(lexer.PuncToken, delimiter)
    end
  end

  return result
end

function Parser:parseSpec()
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

function Parser:parseProp()
  local token = self.stream:peek()
  local custom = false
  if token:isa(lexer.PuncToken) and token.value == "~" then
    custom = true
  end

  local name = self:parseIdent()
  self:skip(lexer.PuncToken, ":")

  local value = self:parseExpr(lexer.PuncToken, ";")

  return node.PropertyNode(token.line, token.col, name, value, custom)
end

function Parser:parseName(classNameAllowed)
  local token = self.stream:next()
  if token:isa(lexer.NameToken) then
    local name = token.value:match("^%s*(.-)%s*$")
    local module = true
    local path, varName
    if name:sub(1, 1) == '"' or name:sub(1, 1) == "'" then
      local _
      _, path, name = name:match("^(['\"])(.+)%1:([%a_][%w_]*)$")
      module = false
    else
      path, name = name:match("^(.+):([%a_][%w]*)$")
    end
    if not path then
      self:error(token, "Malformed name")
    end
    return node.NameNode(token.line, token.col, path, name, module)
  elseif classNameAllowed and token:isa(lexer.ClassNameToken) then
    return node.ClassNameNode(token.line, token.col, token.value)
  elseif token:isa(lexer.TypeRefToken) then
    return node.TypeRefNode(token.line, token.col, token.value)
  else
    self:error(token, "Name " .. (classNameAllowed and "or class name" or "") ..
               "expected")
  end
end

function Parser:parsePath()
  local token = self.stream:next()
  if not token:isa(lexer.StrToken) then
    self:error(token, "Path expected")
  end
  return node.PathNode(token.line, token.col, token.value)
end

function Parser:parseExpr(endType, endValue)
  local value = {}

  local token = self.stream:peek()

  while true do
    local token = self.stream:peek()

    if not token or token:isa(endType) and
        (not endValue or token.value == endValue) then
      break
    end

    if token:isa(lexer.PuncToken) or token:isa(lexer.NumToken) or
        token:isa(lexer.ColorToken) or token:isa(StrToken) or
        token:isa(lexer.IdentToken) then
      table.insert(value, token.value)
    elseif token:isa(lexer.VarRefToken) or token:isa(lexer.CodeToken) then
      table.insert(value, token)
    else
      self:error(token, "Unexpected token in expression")
    end

    self.stream:next()
  end

  return value
end

function Parser:parseTarget()
  local component
  local classes = {}
  local selectors = {}

  -- Component name
  local token = self.stream:peek()
  if token:isa(lexer.NameToken) or token:isa(lexer.ClassNameToken) or
      token:isa(lexer.TypeRefToken) then
    component = self:parseName(true)
  elseif token:isa(lexer.PuncToken) and token.value == "*" then
    component = node.AnyTypeNode()
  end

  -- Classes
  while true do
    local token = self.stream:peek()
    if token:isa(lexer.PuncToken) and token.value == "." then
      self.stream:next()
      table.insert(classes, node.ClassNode(token.line, token.col,
                                           self:parseIdent()))
    else
      break
    end
  end

  -- Selectors
  while true do
    local token = self.stream:peek()
    if token:isa(lexer.PuncToken) and token.value == ":" then
      self.stream:next()
      local custom = false
      local nextToken = self.stream:peek()
      if nextToken:isa(PuncToken) and nextToken.value == "~" then
        custom = true
      end

      local name = self:readIdent()

      local value
      nextToken = self.stream:peek()
      if nextToken:isa(PuncToken) and nextToken.value == "(" then
        value = self:readExpr(lexer.PuncToken, ")")
      end

      table.insert(selectors, node.SelectorNode(token.line, token.col,
                                                name, value, custom))
    else
      break
    end
  end
  if not component and #classes == 0 and #selectors == 0 then
    self:error("cur", "Target expected")
  end

  return node.TargetNode(token.line, token.col, component, classes, selectors)
end


return {
  Parser = Parser,
}

