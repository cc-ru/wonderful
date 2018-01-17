local class = require("lua-objects")

local node = require("wonderful.style.node")

local Context = class(nil, {name = "wonderful.style.parser.Context"})
Context.spaces = {" ", "\t", "\n", "\v"}

function Context:__new__()
  self.vars = {}
  self.rules = {}
  self.parsers = {}
end

function Context:parse(buf)
  local nodes = {}

  local sl, sc = 1, 1

  local function readWord(stopAt)
    return buf:readTo(self.spaces)
  end

  local function skipSpaces()
    return buf:readWhileIn(self.spaces)
  end

  while true do
    local word = readWord()
    if word == "import" then
      table.insert(tokens, ...)
    end
  end
end
