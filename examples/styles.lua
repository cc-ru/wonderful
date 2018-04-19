-- Doesn't render anything. Creates two rectangles and applies
-- the styles from style/styles.wsf.
--
-- Uses: styles, attributes.

local WonderfulStyle = require("wonderful.style").WonderfulStyle
local interpreter = require("wonderful.style.interpreter")
local node = require("wonderful.style.node")
local lexer = require("wonderful.style.lexer")
local Element = require("wonderful.element").Element
local Classes = require("wonderful.element.attribute").Classes
local class = require("lua-objects")

local Rect = class(Element, {name = "Rectangle"})

local s = WonderfulStyle():addTypes({
  Rectangle = interpreter.Type(Rect)
}):parseFromStream(io.open("/home/wonderful/test/style/styles.wsf", "r"))

local rect1 = Rect()
rect1:set(Classes("class"))

local rect2 = Rect()

print(s:getProperty(rect1, "test"))
print(s:getProperty(rect1, "color"):get())
print(s:getProperty(rect2, "color"):get())
