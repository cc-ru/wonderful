local DELIMETERS = {" ", "\n", "  "}
local IDENTIFIERS = {"{", "}", "#", "=", '"', '"', ";", ":", ".", "$", "@",
                     "[", "]", "!"}
local TOKEN_TYPE = {
  WORD = 1,
  COMMENT = 2,
  IDENTIFIER = 3,
  NUMBER = 4,
  STRING = 5
}

local function icontains(tbl, object)
  for i = 1, #tbl do
    if tbl[i] == object then
      return true
    end
  end
  return false
end

local function checkDelimeters(char)
  return icontains(DELIMETERS, char)
end

local function checkIdentifiers(char, idents)
  return icontains(idents, char)
end

local function isNumber(char)
  return string.match(char, "%d")
end

local function getNumber(str, pos)
  return string.match(str, "%d+", pos)
end

local function getString(str, ch, pos)
  local _, e = string.find(str, ch, pos + 1)
  return string.sub(str, pos + 1, e - 1), e
end

local function find(tbl, value, pos)
  for i = pos, #tbl do
    if tbl[i].value == value then
      return i
    end
  end
  return -1
end

function tokenize(str, idents)
  local identifiers = nil
  if idents ~= nil then
    identifiers = idents
  else
    identifiers = IDENTIFIERS
  end
  local tokens = {}
  local strLen = #str
  local i = 0
  local next = function()
    return string.sub(str, i + 1, i + 1)
  end

  local current = function()
    return string.sub(str, i, i)
  end

  local addToken = function(token, t)
    if t == TOKEN_TYPE.WORD and type(token) == "string" and #token == 0 then
      return
    end
    table.insert(tokens, {value = token, type = t})
  end

  local currentToken = ""
  while i < strLen do
    i = i + 1
    local char = current()
    if char == '"' then
      local string, pos = getString(str, '"', i)
      addToken(string, TOKEN_TYPE.STRING)
      i = pos
    elseif char == "/" then
      local oneLineComment = string.match(str, "//.-\n", i)
      local multiLineComment = string.match(str, "/%*.*%*/")
      if oneLineComment ~= nil then
        local commentLen = #oneLineComment
        addToken(string.sub(oneLineComment, 3, commentLen - 1), TOKEN_TYPE.COMMENT)
        i = i + commentLen - 1
      end
      if multiLineComment ~= nil then
        local commentLen = #multiLineComment
        addToken(string.sub(multiLineComment, 3, commentLen - 2), TOKEN_TYPE.COMMENT)
        i = i + commentLen
      end
    else
      if isNumber(char) then
        local number = getNumber(str, i)
        i = i + #number - 1
        addToken(tonumber(number), TOKEN_TYPE.NUMBER)
      elseif checkIdentifiers(char, identifiers) then
        addToken(currentToken, TOKEN_TYPE.WORD)
        currentToken = ""
        addToken(char, TOKEN_TYPE.IDENTIFIER)
      elseif checkDelimeters(char) then
        while i < strLen do
          i = i + 1
          if not checkDelimeters(current()) then
            break
          end
        end
        if i >= strLen then
          break
        end
        i = i - 1
        addToken(currentToken, TOKEN_TYPE.WORD)
        currentToken = ""
      else
        currentToken = currentToken .. char
      end
    end
  end

  if #currentToken > 0 then
    addToken(currentToken, TOKEN_TYPE.WORD)
  end

  return tokens
end

return {
  tokenize = tokenize
}