--- A file buffer that keeps track of the current column and row in the file.
-- @module wonderful.style.buffer

local unicode = require("unicode")

local class = require("lua-objects")

local ulen = unicode.len
local usub = unicode.sub

local Buffer = class(nil, {name = "wonderful.style.buffer.Buffer"})

function Buffer:__new__(buf)
  self.lines = {}
  self.col = 1
  self.line = 1

  if type(buf) == "string" then
    local pos = 1
    local eof = false
    while not eof do
      local line
      local nlPos = buf:find("[\r\n]", pos)
      if nlPos then
        if buf:sub(nlPos, nlPos + 1) == "\r\n" then
          line = buf:sub(pos, nlPos - 1)
          pos = nlPos + 2
        elseif buf:sub(nlPos, nlPos) == "\n" then
          line = buf:sub(pos, nlPos - 1)
          pos = nlPos + 1
        end
      else
        line = buf:sub(pos)
        eof = true
      end
      if line then
        if not eof then
          line = line .. "\n"
        end
        table.insert(self.lines, line)
      end
    end
  else
    while true do
      local line = buf:readLine()
      if line then
        table.insert(self.lines, line .. "\n")
      else
        break
      end
    end
    buf:close()
  end
end

function Buffer:getCur()
  if not self.lines[self.line] or ulen(self.lines[self.line]) < self.col then
    return nil
  end

  return usub(self.lines[self.line], self.col, self.col)
end

function Buffer:getLine(n)
  return self.lines[n]
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
  if noSeek then
    self:seek(-ulen(result))
  end
  return result, eof
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

function Buffer:seekLines(n)
  if n == 0 then
    return 0
  end
  local sought = n
  if n < 0 and (self.line + sought) < 1 then
    sought = -(self.line - 1)
  elseif n > 0 and (self.line + sought) > #self.lines + 1 then
    sought = #self.lines - self.line + 1
  end
  self.line = self.line + sought
  self.col = 1
  return sought
end

function Buffer:readTo(stopAt)
  if type(stopAt) == "string" then
    stopAt = {stopAt}
  elseif not stopAt or #stopAt == 0 then
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
      return result, nil, "eof"
    end
    for k, v in ipairs(stopAt) do
      if v == usub(block, 1, ulen(v)) then
        self:seek(ulen(v))
        return result, v
      end
    end
    result = result .. usub(block, 1, 1)
    self:seek(1)
  end
end

function Buffer:readWhileIn(allowed, plain)
  plain = plain == nil and true
  return self:readWhile(function(char)
    return char:find(allowed, 1, plain)
  end)
end

function Buffer:readWhile(predicate)
  local result = ""
  local n = 0

  while true do
    local char = self:getCur()

    if not char then
      return result, "eof"
    end

    n = n + 1

    if not predicate(char, n) then
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

return {
  Buffer = Buffer,
}

