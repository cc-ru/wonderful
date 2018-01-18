-- A file buffer that keeps track of the current column and row in the file.
local unicode = require("unicode")

local class = require("lua-objects")

local ulen = unicode.len
local uset = unicode.sub

local Buffer = class(nil, {name = "wonderful.style.buffer.Buffer"})

function Buffer:__new__(buf)
  self.lines = {}
  self.col = 1
  self.line = 1

  while true do
    local line = buf:readLine()
    if line then
      table.insert(self.lines, line)
    end
  end
end

function Buffer:getCur()
  return usub(self.lines[self.line], self.col, self.col)
end

function Buffer:read(n, noSeek)
  local result, eof = ""
  for i = 1, n, 1 do
    local char = self:getCur()

    if not char then
      eof = "eof"
      break
    end

    result = result .. char
    self:seek(1)
  end
  if not noSeek then
    self:seek(-ulen(result))
  end
  return result
end

function Buffer:seek(n)
  if n == 0 then
    return 0
  end
  local sought = 0
  if n < 0 then
    for i = 1, math.abs(n), 1 do
      if self.line == 1 and self.col == 1 then
        return sought
      end
      if self.col == 1 then
        self.line = self.line - 1
        self.col = ulen(self.lines[self.line])
      else
        self.col = self.col - 1
      end
      sought = sought - 1
    end
  else
    for i = 1, n, 1 do
      if self.line > #self.lines then
        return sought
      end
      if ulen(self.lines[self.line]) > self.col then
        self.col = self.col + 1
      else
        self.col = 1
        self.line = self.line + 1
      end
      sought = sought + 1
    end
  end
  return sought
end

function Buffer:readTo(stopAt)
  if not stopAt or #stopAt == 0 then
    stopAt = {""}
  end

  -- Sort by length
  table.sort(stopAt, function(lhs, rhs)
    return ulen(lhs) > ulen(rhs)
  end)

  local blockSize = ulen(stopAt[1])

  local result = ""
  while true do
    local block = self:read(blockSize, true)
    if block == "" then
      return result, "eof"
    end
    for k, v in pairs(stopAt) do
      if v == usub(block, 1, ulen(v)) then
        self:seek(ulen(v))
        return result, v
      end
    end
    result = result .. usub(block, 1, 1)
    self:seek(1)
  end
end

function Buffer:readWhileIn(allowed)
  local result = ""
  while true do
    local char = self:getCur()
    if not char then
      return result, "eof"
    end
    if not allowed:find(char, 1, true) then
      return result
    end
    result = result .. char
    self:seek(1)
  end
  return result
end

function Buffer:getPosition()
  return self.line, self.col
end
