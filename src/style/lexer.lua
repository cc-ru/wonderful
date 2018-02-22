local unicode = require("unicode")

local class = require("lua-objects")

local tblUtil = require("wonderful.util.table")

local isin = tblUtil.isin
local ulen = unicode.len
local usub = unicode.sub

local Token = class(nil, {name = "wonderful.style.lexer.Token"})

function Token:__new__(line, col, value)
  self.line = line
  self.col = col
  self.value = value
end

local PuncToken = class(Token, {name = "wonderful.style.lexer.PuncToken"})
local NumToken = class(Token, {name = "wonderful.style.lexer.NumToken"})
local ColorToken = class(Token, {name = "wonderful.style.lexer.ColorToken"})
local StrToken = class(Token, {name = "wonderful.style.lexer.StrToken"})
local KwToken = class(Token, {name = "wonderful.style.lexer.KwToken"})
local IdentToken = class(Token, {name = "wonderful.style.lexer.IdentToken"})
local OpToken = class(Token, {name = "wonderful.style.lexer.OpToken"})
local CodeToken = class(Token, {name = "wonderful.style.lexer.CodeToken"})
local NameToken = class(Token, {name = "wonderful.style.lexer.NameToken"})
local ClassNameToken = class(
  Token,
  {name = "wonderful.style.lexer.ClassNameToken"}
)
local VarRefToken = class(Token, {name = "wonderful.style.lexer.VarRefToken"})
local TypeRefToken = class(Token, {name = "wonderful.style.lexer.TypeRefToken"})

local TokenStream = class(nil, {name = "wonderful.style.lexer.TokenStream"})

TokenStream.keywords = {"import", "pub", "type"}
TokenStream.punc = ",.{}();@~:*"
TokenStream.identFirst = "[A-Za-z_]"
TokenStream.ident = "[A-Za-z0-9_-]"
TokenStream.operators = {"=", ">", ">>", "~>", "~>>"}

table.sort(TokenStream.operators, function(lhs, rhs)
  return not (ulen(lhs) < ulen(rhs))
end)

TokenStream.opMaxLen = ulen(TokenStream.operators[1])

function TokenStream:__new__(buf)
  self.currentToken = nil
  self.col = 0
  self.line = 0
  self.buf = buf
  self._eof = false
end

function TokenStream:next()
  if not self:eof() then
    local token = self.currentToken or self:readNext()
    self.currentToken = nil
    return token
  else
    return nil, "eof"
  end
end

function TokenStream:peek()
  self.currentToken = self.currentToken or self:readNext()
  return self.currentToken
end

function TokenStream:eof()
  return self._eof
end

function TokenStream:error(msg)
  io.stderr:write(self.buf:getLine(self.line))
  io.stderr:write((" "):rep(self.col - 1) .. "^")
  error(self.line .. ":" .. self.col .. ": " .. msg)
end

function TokenStream:readNext()
  self:skipSpaces()
  self.col, self.line = self.buf:getPosition()
  local char2 = self.buf:read(2, true)

  if char2 == "" then
    self._eof = true
    return "eof"
  end

  if char2 == "//" then
    self:skipComment(false)
    self:readNext()
  elseif char2 == "/*" then
    self:skipComment(true)
    self:readNext()
  end

  char = usub(char2, 1, 1)

  if char2 == "$(" then
    self:readCode()
  elseif char == '"' or char == "'" then
    self:readString()
  elseif char == "[" then
    self:readClassName()
  elseif char == "<" then
    self:readName()
  elseif tonumber(char, 10) then
    self:readNumber()
  else
    local opChunk
    if self.opMaxLen == 1 then
      opChunk = char
    elseif self.opMaxLen == 2 then
      opChunk = char2
    else
      opChunk = self.buf:read(self.opMaxLen, true)
    end
    local operator
    for _, v in ipairs(self.operators) do
      if usub(opChunk, 1, ulen(v)) == v then
        operator = v
        break
      end
    end
    if operator then
      self:readOperator(operator)
    elseif char2:match("#%x") then
      self:readColor()
    elseif char == "$" then
      self:readVarRef()
    elseif char:match(self.identFirst) then
      self:readIdent()
    elseif self.punc:find(char, 1, true) then
      self:readPunc()
    end
  end
end

function TokenStream:skipSpaces()
  self.buf:readWhileIn("%s", false)
end

function TokenStream:skipComment(multiline)
  if not multiline then
    self.buf:seekLines(1)
  else
    self.buf:readTo("*/")
  end
end

function TokenStream:readString()
  local start = self.buf:getCur()
  local result, endChar = self.buf:readTo(start)
  if endChar ~= start then
    -- unclosed string
    self:error("String not closed")
  end
  table.insert(self.tokens, StrToken(result))
end

function TokenStream:readNumber()
  local dot = false
  local result = self.buf:readWhile(function(char)
    if char == "." and dot then
      self:error("Bad number")
    end
    if char == "." then
      dot = true
      return true
    end
    return char:match("%d")
  end)
  result = tonumber(result, 10)
  table.insert(self.tokens, NumToken(result))
end

function TokenStream:readPunc()
  table.insert(self.tokens, PuncToken(self.buf:read(1)))
end

function TokenStream:readColor()
  self.buf:seek(1)
  local result = self.buf:readWhileIn("%x", false)
  if #result == 3 then
    result = result .. result
  end
  if #result == 6 then
    table.insert(self.tokens, ColorToken(tonumber(result, 16)))
  end
  self:error("Bad color")
end

function TokenStream:readCode()
  self.buf:seek(2)
  local result, endChar = self.buf:readTo(")")
  if endChar ~= ")" then
    self:error("Lua code expression not closed")
  end
  table.insert(self.tokens, CodeToken(result))
end

function TokenStream:readName()
  self.buf:seek(1)
  local result, endChar = self.buf:readTo(">")
  if endChar ~= ">" then
    self:error("Name not closed")
  end
  table.insert(self.tokens, NameToken(result))
end

function TokenStream:readClassName()
  self.buf:seek(1)
  local result, endChar = self.buf:readTo("]")
  if endChar ~= "]" then
    self:error("Class name not closed")
  end
  table.insert(self.tokens, ClassNameToken(result))
end

function TokenStream:readOperator(op)
  self.buf:seek(ulen(op))
  table.insert(self.tokens, OpToken(op))
end

function TokenStream:readIdent()
  local result = self:getIdent()
  if isin(result, self.keywords) then
    table.insert(self.tokens, KwToken(result))
  else
    table.insert(self.tokens, IdentToken(result))
  end
end

function TokenStream:readVarRef()
  self.buf:seek(1)
  local name = self:getIdent()
  table.insert(self.tokens, VarRefToken(name))
end

function TokenStream:readTypeRef()
  self.buf:seek(1)
  local name = self:getIdent()
  table.insert(self.tokens, TypeRefToken(name))
end

function TokenStream:getIdent()
  local firstChar = self.buf:read(1)
  if not firstChar:match(self.identFirst) then
    self:error("Bad identifier name")
  end
  return firstChar .. self.buf:readWhileIn(self.ident, false)
end

return {
  Token = Token,

  PuncToken = PuncToken,
  NumToken = NumToken,
  ColorToken = ColorToken,
  StrToken = StrToken,
  KwToken = KwToken,
  IdentToken = IdentToken,
  OpToken = OpToken,
  CodeToken = CodeToken,
  NameToken = NameToken,
  ClassNameToken = ClassNameToken,
  VarRefToken = VarRefToken,
  TypeRefToken = TypeRefToken,

  TokenStream = TokenStream,
}

