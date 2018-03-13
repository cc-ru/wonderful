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

function Token:__tostring__()
  local result = ""
  if self.line then
    result = result .. "L" .. tostring(self.line)
    if self.col then
      result = result .. ":" .. tostring(self.col) .. ":"
    end
    result = result .. " "
  end
  result = result .. (self.NAME or "Unnamed token")
  if self.value then
    result = result .. " = " .. ("%q"):format(tostring(self.value))
  end
  return result
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
TokenStream.punc = ",.{}();~:*"
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
  local token, reason = self:peek()
  self.currentToken = nil
  return token, reason
end

function TokenStream:peek()
  if not self.currentToken then
    local reason
    self.currentToken, reason = self:readNext()
    if not self.currentToken then
      return nil, reason
    end
  end
  return self.currentToken
end

function TokenStream:eof()
  return self._eof
end

function TokenStream:error(msg)
  local line = self.buf:getLine(self.line)
  if line then
    io.stderr:write(self.buf:getLine(self.line))
    io.stderr:write((" "):rep(self.col - 1) .. "^\n")
  end
  error("L" .. self.line .. ":" .. self.col .. ": " .. msg, 2)
end

function TokenStream:readNext()
  self:skipSpaces()
  self.col, self.line = self.buf:getPosition()
  local char2 = self.buf:read(2, true)

  if char2 == "" then
    print("lexer: eof!")
    self._eof = true
    return nil, "eof"
  end

  if char2 == "//" then
    self:skipComment(false)
    return self:readNext()
  elseif char2 == "/*" then
    self:skipComment(true)
    return self:readNext()
  end

  local char = usub(char2, 1, 1)
  print(char)

  if char2 == "$(" then
    return self:readCode()
  elseif char == '"' or char == "'" then
    return self:readString()
  elseif char == "[" then
    return self:readClassName()
  elseif char == "<" then
    return self:readName()
  elseif tonumber(char, 10) or tonumber(char2, 10) then
    -- `tonumber(char2, 10)` allows to parse negative numbers
    return self:readNumber()
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
      return self:readOperator(operator)
    elseif char2:match("#%x") then
      return self:readColor()
    elseif char == "$" then
      return self:readVarRef()
    elseif char == "@" then
      return self:readTypeRef()
    elseif char:match(self.identFirst) then
      return self:readIdent()
    elseif self.punc:find(char, 1, true) then
      return self:readPunc()
    end
  end

  self:error("Unknown token")
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
  return StrToken(self.col, self.line, result)
end

function TokenStream:readNumber()
  local dot = false

  local result = self.buf:readWhile(function(char, n)
    if n == 1 and char == "-" then
      return true
    end

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
  return NumToken(self.col, self.line, result)
end

function TokenStream:readPunc()
  return PuncToken(self.col, self.line, self.buf:read(1))
end

function TokenStream:readColor()
  self.buf:seek(1)
  local result = self.buf:readWhileIn("%x", false)
  if #result == 3 then
    result = result:gsub(".", "%1%1")
  end
  if #result == 6 then
    return ColorToken(self.col, self.line, tonumber(result, 16))
  end
  self:error("Bad color")
end

function TokenStream:readCode()
  self.buf:seek(2)
  local result, endChar = self.buf:readTo(")")
  if endChar ~= ")" then
    self:error("Lua code expression not closed")
  end
  return CodeToken(self.col, self.line, result)
end

function TokenStream:readName()
  self.buf:seek(1)
  local result, endChar = self.buf:readTo(">")
  if endChar ~= ">" then
    self:error("Name not closed")
  end
  return NameToken(self.col, self.line, result)
end

function TokenStream:readClassName()
  self.buf:seek(1)
  local result, endChar = self.buf:readTo("]")
  if endChar ~= "]" then
    self:error("Class name not closed")
  end
  return ClassNameToken(self.col, self.line, result)
end

function TokenStream:readOperator(op)
  self.buf:seek(ulen(op))
  return OpToken(self.col, self.line, op)
end

function TokenStream:readIdent()
  local result = self:getIdent()
  if isin(result, self.keywords) then
    return KwToken(self.col, self.line, result)
  else
    return IdentToken(self.col, self.line, result)
  end
end

function TokenStream:readVarRef()
  self.buf:seek(1)
  local name = self:getIdent()
  return VarRefToken(self.col, self.line, name)
end

function TokenStream:readTypeRef()
  self.buf:seek(1)
  local name = self:getIdent()
  return TypeRefToken(self.col, self.line, name)
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

