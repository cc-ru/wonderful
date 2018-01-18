local unicode = require("unicode")

local class = require("lua-objects")

local node = require("wonderful.style.node")

local usub = unicode.sub

local Context = class(nil, {name = "wonderful.style.parser.Context"})
Context.spaces = {" ", "\t", "\n", "\v"}
Context.boundaries = {
  ["["] = "]",
  ["("] = ")",
  ["{"] = "}",
  ["<"] = ">",
  ['"'] = '"',
  ["'"] = "'",
}

function Context:__new__()
  self.vars = {}
  self.rules = {}
  self.parsers = {}
end

function Context:parse(buf)
  local nodes = {}

  local sl, sc, word = 1, 1

  local function skipSpaces()
    return buf:readWhileIn(self.spaces)
  end

  local function readWord()
    return buf:readTo(self.spaces)
  end

  local function readBoundary()
    local start = buf:getCur()
    if not start or not self.boundaries[start] then
      return nil
    end
    local result, eof = buf:readTo(self.boundaries[start])
    if eof or result == "" then
      error("bad boundary")
    end
    return result, start
  end

  local function readExpression(stopAt)
    stopAt = stopAt or ";"
    return buf:readTo(stopAt)
  end

  while true do
    skipSpaces()
    sl, sc, word = readWord()
    if word == "import" then
      skipSpaces()
      local path, start = readBoundary()
      local importName
      if start == "[" then
        importName = node.NameNode(usub(path, 2, -2))
      elseif start == '"' or start == "'" then
        importName = node.PathNode(usub(path, 2, -2))
      end
      table.insert(tokens, node.ImportNode(importName))
    end
  end
end
