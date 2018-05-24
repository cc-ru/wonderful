--- Buffer storage classes for Lua 5.2.
-- @module wonderful.buffer.storage52

local class = require("lua-objects")

--- The base buffer storage class.
local BufferStorage = class(
  nil,
  {name = "wonderful.buffer.storage.BufferStorage"}
)

--- The base buffer storage class.
-- @type BufferStorage

--- The data struct.
-- Given i, j, the cell's character and packed color should be available
-- as `storage.data[i][j]` and `storage.data[i][j + 1]`, respectively.
-- @field BufferStorage.data

--- The abstract base buffer constructor.
-- @tparam int w a width
-- @tparam int h a height
function BufferStorage:__new__(w, h)
  error(("%s does not implement a constructor"):format(self.NAME))
end

--- The abstract clear method that must clear the buffer storage.
function BufferStorage:clear()
  error(("%s does not implement clear"):format(self.NAME))
end

--- The abstract main cell index getter.
-- @tparam int x a cell column number
-- @tparam int y a cell row number
-- @treturn int i
-- @treturn int j
function BufferStorage:indexMain(x, y)
  error(("%s does not implement indexMain"):format(self.NAME))
end

--- The abstract diff cell index getter.
-- @tparam int x a cell column number
-- @tparam int y a cell row number
-- @treturn int i
-- @treturn int j
function BufferStorage:indexDiff(x, y)
  error(("%s does not implement indexDiff"):format(self.NAME))
end

--- Get a given main cell's character and packed color.
-- @tparam int x a cell column number
-- @tparam int y a cell row number
-- @treturn ?string a character
-- @treturn ?int a packed color
function BufferStorage:getMain(x, y)
  local i, j = self:indexMain(x, y)
  return self.data[i][j], self.data[i][j + 1]
end

--- Get a given diff cell's character and packed color.
-- @tparam int x a cell column number
-- @tparam int y a cell row number
-- @treturn ?string a character
-- @treturn ?int a packed color
function BufferStorage:getDiff(x, y)
  local i, j = self:indexDiff(x, y)
  return self.data[i][j], self.data[i][j + 1]
end

---
-- @section end

--- The T1 buffer storage class.
local BufferStorageT1 = class(
  BufferStorage,
  {name = "wonderful.buffer.storage.BufferStorageT1"}
)

function BufferStorageT1:__new__(w, h)
  self.w = w
  self.h = h
  self:clear()
end

function BufferStorageT1:clear()
  self.data = {{}, {}, {}}
end

function BufferStorageT1:indexMain(x, y)
  local i = 2 * ((y - 1) * self.w + x) - 1
  return (i - i % 1024) / 1024 + 1, (i - 1) % 1024 + 1
end

function BufferStorageT1:indexDiff(x, y)
  local i = 1599 + 2 * ((y - 1) * self.w + x)
  return (i - i % 1024) / 1024 + 1, (i - 1) % 1024 + 1
end

--- The T2 buffer storage class.
local BufferStorageT2 = class(
  BufferStorage,
  {name = "wonderful.buffer.storage.BufferStorageT2"}
)

function BufferStorageT2:__new__(w, h)
  self.w = w
  self.h = h
  self:clear()
end

function BufferStorageT2:clear()
  self.data = {{}, {}}
end

function BufferStorageT2:indexMain(x, y)
  local i = 2 * ((y - 1) * self.w + x) - 1
  return (i - i % 4096) / 4096 + 1, (i - 1) % 4096 + 1
end

function BufferStorageT2:indexDiff(x, y)
  local i = 3999 + 2 * ((y - 1) * self.w + x)
  return (i - i % 4096) / 4096 + 1, (i - 1) % 4096 + 1
end

--- The T3 buffer storage class.
local BufferStorageT3 = class(
  BufferStorage,
  {name = "wonderful.buffer.storage.BufferStorageT3"}
)

function BufferStorageT3:__new__(w, h)
  self.w = w
  self.h = h
  self:clear()
end

function BufferStorageT3:clear()
  self.data = {}

  for i = 1, 32, 1 do
    self.data[i] = {}
  end
end

function BufferStorageT3:indexMain(x, y)
  local i = 2 * ((y - 1) * self.w + x) - 1
  return (i - i % 1024) / 1024 + 1, (i - 1) % 1024 + 1
end

function BufferStorageT3:indexDiff(x, y)
  local i = 15999 + 2 * ((y - 1) * self.w + x)
  return (i - i % 1024) / 1024 + 1, (i - 1) % 1024 + 1
end

---
-- @export
return {
  BufferStorage = BufferStorage,
  BufferStorageT1 = BufferStorageT1,
  BufferStorageT2 = BufferStorageT2,
  BufferStorageT3 = BufferStorageT3,
}