local class = require("lua-objects")

local BufferStorage = class(
  nil,
  {name = "wonderful.buffer.storage.BufferStorage"}
)

function BufferStorage:__new__(w, h)
  error(("%s does not implement a constructor"):format(self.NAME))
end

function BufferStorage:indexMain(x, y)
  error(("%s does not implement indexMain"):format(self.NAME))
end

function BufferStorage:indexDiff(x, y)
  error(("%s does not implement indexDiff"):format(self.NAME))
end

function BufferStorage:getMain(x, y)
  local i, j, k = self:indexMain(x, y)
  return self.data[i][j][k], self.data[i][j][k + 1]
end

function BufferStorage:getDiff(x, y)
  local i, j, k = self:indexDiff(x, y)
  return self.data[i][j][k], self.data[i][j][k + 1]
end

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
  self.data = {{{}, {}, {}}}
end

function BufferStorageT1:indexMain(x, y)
  local i = (((y - 1) * self.w + x) << 1) - 1
  return 1, ((i - 1) >> 10) + 1, (i - 1) % 1024 + 1
end

function BufferStorageT1:indexDiff(x, y)
  local i = 1599 + (((y - 1) * self.w + x) << 1)
  return 1, ((i - 1) >> 10) + 1, (i - 1) % 1024 + 1
end

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
  self.data = {{{}, {}}}
end

function BufferStorageT2:indexMain(x, y)
  local i = (((y - 1) * self.w + x) << 1) - 1
  return 1, ((i - 1) >> 12) + 1, (i - 1) % 4096 + 1
end

function BufferStorageT2:indexDiff(x, y)
  local i = 3999 + (((y - 1) * self.w + x) << 1)
  return 1, ((i - 1) >> 12) + 1, (i - 1) % 4096 + 1
end

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
  self.data = {{}}

  for i = 1, 32, 1 do
    self.data[1][i] = {}
  end
end

function BufferStorageT3:indexMain(x, y)
  local i = (((y - 1) * self.w + x) << 1) - 1
  return 1, ((i - 1) >> 10) + 1, (i - 1) % 1024 + 1
end

function BufferStorageT3:indexDiff(x, y)
  local i = 15999 + (((y - 1) * self.w + x) << 1)
  return 1, ((i - 1) >> 10) + 1, (i - 1) % 1024 + 1
end

return {
  BufferStorage = BufferStorage,
  BufferStorageT1 = BufferStorageT1,
  BufferStorageT2 = BufferStorageT2,
  BufferStorageT3 = BufferStorageT3,
}
