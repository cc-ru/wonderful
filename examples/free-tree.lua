-- Creates free trees (their roots are not a Document),
-- and inserts them into the rooted tree.
--
-- [Document
--  +- [level1
--      +- a
--      +- b
--      +- [level2
--          +- d
--          +- e
--          +- f]
--      +- c]
--
-- The stacking context is expected to be like this:
-- - Document
-- - level1
-- - a
-- - b
-- - level2
-- - c
-- - d
-- - e
-- - f
local class = require("lua-objects")
local wonderful = require("wonderful")

local wmain = wonderful.Wonderful {
  debug = false
}

local doc = wmain:addDocument()

local Container = class(wonderful.element.Element, {name = "Container"})

function Container:__new__(name)
  self:superCall("__new__")
  self.name = name
end

function Container:__tostring__()
  return "Container { name = " .. self.name .. " }"
end

local a = Container("a")
local b = Container("b")
local c = Container("c")
local d = Container("d")
local e = Container("e")
local f = Container("f")

local level2 = Container("level2")
level2:appendChild(d)
level2:appendChild(e)
level2:appendChild(f)

local level1 = Container("level1")
level1:appendChild(a)
level1:appendChild(b)
level1:appendChild(level2)
level1:appendChild(c)

doc:appendChild(level1)

print("Stacking context:")

for i, el in ipairs(doc.stackingContext.static) do
  print(("%2d: %s"):format(i, tostring(el)))
end
