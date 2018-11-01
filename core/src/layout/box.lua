-- Copyright 2018 the wonderful GUI project authors
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

--- The box layout.
-- @module wonderful.layout.box

local class = require("lua-objects")

local Box = require("wonderful.geometry").Box
local Layout = require("wonderful.layout").Layout
local ListMixin = require("wonderful.element.node").ListMixin
local Margin = require("wonderful.geometry").Margin
local Padding = require("wonderful.geometry").Padding

--- The enum of directions in which children can be layed out.
local Direction = {
  TopToBottom = 0,  --- The first child is at the top, consequent ones are put below it.
  BottomToTop = 1,  --- The first child is at the bottom, consequent ones are put above it.
  LeftToRight = 2,  --- The first child is at the left, consequent ones are put to the right of it.
  RightToLeft = 3,  --- The first child is at the right, consequent ones are put to the left of it.
}

local function getVerticalDirection(reversed)
  return reversed and Direction.BottomToTop or Direction.TopToBottom
end

local function getHorizontalDirection(reversed)
  return reversed and Direction.RightToLeft or Direction.LeftToRight
end

--- The margin class.
-- @cl Margin
local Margin = class(nil, {name = "wonderful.layout.box.Margin"})

--- @type Margin

--- Construct a new instance.
-- @tparam BoxLayout layout the layout to which to be bind the instance
-- @tparam ?int l the left margin
-- @tparam ?int t the top margin
-- @tparam ?int r the right margin
-- @tparam ?int b the bottom margin
function Margin:__new__(layout, l, t, r, b)
  self._layout = layout
  self:set(l, t, r, b)
end

--- Set the margins. A shorthand for setting each margin individually.
-- @tparam ?int l the left margin
-- @tparam ?int t the top margin
-- @tparam ?int r the right margin
-- @tparam ?int b the bottom margin
function Margin:set(l, t, r, b)
  self:setLeft(l)
  self:setTop(t)
  self:setRight(r)
  self:setBottom(b)
end

--- Set the left margin.
-- @tparam ?int l the left margin
function Margin:setLeft(l)
  self._l = type(l) == "number" and l or 0
  self._layout:requestComposition()
end

--- Set the top margin.
-- @tparam ?int t the top margin
function Margin:setTop(t)
  self._t = type(t) == "number" and t or 0
  self._layout:requestComposition()
end

--- Set the right margin.
-- @tparam ?int r the right margin
function Margin:setRight(r)
  self._r = type(t) == "number" and r or 0
  self._layout:requestComposition()
end

--- Set the bottom margin.
-- @tparam ?int b the bottom margin
function Margin:setBottom(b)
  self._b = type(b) == "number" and b or 0
  self._layout:requestComposition()
end

--- Get the left margin.
-- @treturn int the left margin
function Margin:getLeft()
  return self._l
end

--- Get the top margin.
-- @treturn int the left margin
function Margin:getTop()
  return self._t
end

--- Get the right margin.
-- @treturn int the right margin
function Margin:getRight()
  return self._r
end

--- Get the bottom margin.
-- @treturn int the bottom margin
function Margin:getBottom()
  return self._b
end

--- @section end

--- The padding class.
-- @cl Padding
local Padding = class(nil, {name = "wonderful.layout.box.Padding"})

--- @type Padding

--- Construct a new instance.
-- @tparam BoxLayout layout the layout to which to be bind the instance
-- @tparam ?int l the left padding
-- @tparam ?int t the top padding
-- @tparam ?int r the right padding
-- @tparam ?int b the bottom padding
function Padding:__new__(layout, l, t, r, b)
  self._layout = layout
  self:set(l, t, r, b)
end

--- Set the paddings. A shorthand for setting each padding individually.
-- @tparam ?int l the left padding
-- @tparam ?int t the top padding
-- @tparam ?int r the right padding
-- @tparam ?int b the bottom padding
function Padding:set(l, t, r, b)
  self:setLeft(l)
  self:setTop(t)
  self:setRight(r)
  self:setBottom(b)
end

--- Set the left padding.
-- @tparam ?int l the left padding
function Padding:setLeft(l)
  self._l = type(l) == "number" and l or 0
  self._layout:requestComposition()
end

--- Set the top padding.
-- @tparam ?int t the top padding
function Padding:setTop(t)
  self._t = type(t) == "number" and t or 0
  self._layout:requestComposition()
end

--- Set the right padding.
-- @tparam ?int r the right padding
function Padding:setRight(r)
  self._r = type(t) == "number" and r or 0
  self._layout:requestComposition()
end

--- Set the bottom padding.
-- @tparam ?int b the bottom padding
function Padding:setBottom(b)
  self._b = type(b) == "number" and b or 0
  self._layout:requestComposition()
end

--- Get the left padding.
-- @treturn int the left padding
function Padding:getLeft()
  return self._l
end

--- Get the top padding.
-- @treturn int the left padding
function Padding:getTop()
  return self._t
end

--- Get the right padding.
-- @treturn int the right padding
function Padding:getRight()
  return self._r
end

--- Get the bottom padding.
-- @treturn int the bottom padding
function Padding:getBottom()
  return self._b
end

--- @section end

--- The box layout.
-- @cl BoxLayout
-- @extends wonderful.element.node.ListMixin
-- @extends wonderful.layout.Layout
local BoxLayout = class({ListMixin, Layout},
                        {name = "wonderful.layout.box.BoxLayout"})

--- @type BoxLayout

--- Construct a new instance.
-- @tparam table args keyword argument table
-- @tparam number args.direction the direction in which to lay children out
-- @see Direction
function BoxLayout:__new__(args)
  self:superCall("__new__", args)
  self._direction = args.direction

  self._padding = Padding(self, args.padding and table.unpack(args.padding))

  -- [element] => (wonderful.geometry.Margin) margin
  self._margins = {}

  -- [element] => (number) stretch
  self._stretch = {}
end

--- Set the direction in which to lay children out.
--
-- Automatically issues composition request.
--
-- @tparam number direction one of `Direction` values
function BoxLayout:setDirection(direction)
  if self._direction ~= direction then
    self._direction = direction
    self:requestComposition()
  end
end

--- Get the direction in which children are laid out.
-- @treturn number one of `Direction` values
function BoxLayout:getDirection()
  return self._direction
end

--- Check if the box is laid out vertically.
-- @treturn boolean
function BoxLayout:isVertical()
  return self._direction == Direction.TopToBottom or
         self._direction == Direction.BottomToTop
end

--- Check if the box is laid out in reverse order.
-- @treturn boolean
function BoxLayout:isReversed()
  return self._direction == Direction.BottomToTop or
         self._direction == Direction.RightToLeft
end

--- Return the layout's padding.
--
-- Use the instance's methods to modify values.
--
-- @treturn Padding
-- @usage
-- layout:getPadding():setTop(10)
function BoxLayout:getPadding()
  return self._padding
end

function BoxLayout:sizeHint()
  local width, height = 0, 0

  local vertical = self:isVertical()

  for child in self:getChildren() do
    local hw, hh = child:sizeHint()
    local margin = self._margins[child]

    if vertical then
      width = math.max(width, hw)
      height = height + hh + margin:getTop() + margin:getBottom()
    else
      height = math.max(height, hh)
      width = width + hw + margin:getLeft() + margin:getRight()
    end
  end

  return width, height
end

--- Insert an element at a given index.
-- @tparam int index the index
-- @param element the element
-- @tparam[opt] number stretch the stretch value
-- @treturn Margin the element's margin
-- @see wonderful.element.node.Node:insertChild
-- @usage
-- layout:insertChild(1, element):set(10, 20, nil, nil)
function BoxLayout:insertChild(index, element, stretch)
  self:requestComposition()

  self:superCall("insertChild", index, element)

  local margin = Margin(self)

  self._margins[element] = margin
  self._stretch[element] = stretch or 0

  return margin
end

--- Remove an element at a given index.
-- @tparam int index the index
-- @return[1] the removed element
-- @treturn[2] `false` no element at the given index
-- @see wonderful.element.node.Node:removeChild
function BoxLayout:removeChild(index)
  self:requestComposition()

  local removedElement = self:superCall("removeChild", index)

  if removedElement then
    self._margins[removedElement] = nil
    self._stretch[removedElement] = nil
  end

  return removedElement
end

--- Replace an element at a given index.
--
-- The margin values default to that of the replaced element.
--
-- If the `margin` is `nil`, it defaults to the replaced element's margin. The
-- same is true for the `stretch`.
--
-- @tparam int index the index
-- @param child the element
-- @tparam[opt] number stretch the stretch value
-- @return[1] the replaced element
-- @treturn[1] Margin the element's margin
-- @treturn[2] `false` no element at the given index
-- @see wonderful.element.node.Node:replaceChild
-- @usage
-- select(2, layout:replace(element, element)):setTop(10)
function BoxLayout:replaceChild(index, child, stretch)
  self:requestComposition()

  local removedElement = self:superCall("replaceChild", index, child)

  if removedElement then
    local margin = self._margins[removedElement]

    self._margins[removedElement] = nil
    self._margins[child] = margin

    stretch = stretch or self._stretch[removedElement]

    self._stretch[removedElement] = nil
    self._stretch[child] = stretch

    return removedElement, margin
  end

  return nil
end

function BoxLayout:_compose(layoutBox)
  local reversed = self:isReversed()
  local vertical = self:isVertical()

  local chunks, filled, count, lastMut = self:_buildChildChunks(reversed,
                                                                vertical)

  local pad = self:getPadding()

  local full = vertical and
               (box:getHeight() - pad:getTop() - pad:getBottom()) or
               (box:getWidth() - pad:getLeft() - pad:getRight())

  local basis = (full - filled) / count
  local x = box:getX() + pad:getLeft()
  local y = box:getY() + pad:getTop()

  for j, chunk in ipairs(chunks) do
    if chunk.const then
      x, y = self:_handleConstChunk(chunk, full, reversed, vertical, x, y)
    else
      x, y, filled = self:_handleNonConstChunk(chunk, full, reversed, vertical,
                                               basis, filled, x, y)
    end
  end
end

function BoxLayout:_handleConstChunk(chunk, full, reversed, vertical, x, y)
  for _, el in ipairs(chunk) do
    local w, h = el:sizeHint()
    local margin = self._margins[el]

    if reversed and vertical then
      el:getBoundingBox():set(Box(x + margin:getLeft(),
                                  full - y + margin:getBottom() - h,
                                  w,
                                  h))
    elseif reversed then
      el:getBoundingBox():set(
        Box(full - x - margin:getRight() - w + margin:getLeft(),
            y + margin:getTop(),
            w,
            h)
      )
    else
      el:getBoundingBox():set(Box(x + margin:getLeft(),
                                  y + margin:getTop(),
                                  w,
                                  h))
    end

    if vertical then
      y = y + h + margin:getTop() + margin:getBottom()
    else
      x = x + w + margin:getLeft() + margin:getRight()
    end
  end

  return x, y
end

function BoxLayout:_handleNonConstChunk(chunk, full, reversed, vertical, basis,
                                        filled, x, y)
  local el = chunk.el

  local w, h = el:sizeHint()
  local margin = self._margins[el]

  if vertical then
    h = math.floor(basis * chunk.stretch + 0.5)
  else
    w = math.floor(basis * chunk.stretch + 0.5)
  end

  if j == lastMut and vertical then
    h = full - filled
  elseif j == #chunks then
    w = full - filled
  end

  if reversed and vertical then
    el:getBoundingBox():set(Box(x + margin:getLeft(),
                                full - y + margin:getBottom() - h,
                                w,
                                h))
  elseif reversed then
    el:getBoundingBox():set(
      Box(full - x - margin:getRight() - w + margin:getLeft(),
          y + margin:getTop(),
          w,
          h)
    )
  else
    el:getBoundingBox():set(Box(x + margin:getLeft(),
                                y + margin:getTop(),
                                w,
                                h))
  end

  if vertical then
    filled = filled + h
    y = y + h + margin:getTop() + margin:getBottom()
  else
    filled = filled + w
    x = x + w + margin:getLeft() + margin:getRight()
  end

  return x, y, filled
end

function BoxLayout:_buildChildChunks(reversed, vertical)
  -- TODO: handle BTT and RTL directions
  local chunks = {}
  local i = 0
  local filled = 0
  local count = 0
  local lastMut = 0

  for child in self:getChildren() do
    if self._stretch[child] == 0 then
      local w, h = child:sizeHint()
      local margin = self._margins[child]

      if not chunks[i] or not chunks[i].const then
        i = i + 1
        chunks[i] = {const = true}
      end

      table.insert(chunks[i], child)

      if vertical then
        filled = filled + h + margin:getTop() + margin:getBottom()
      else
        filled = filled + w + margin:getLeft() + margin:getRight()
      end
    else
      local margin = self._margins[child]

      i = i + 1
      count = count + self._stretch[child]

      if vertical then
        filled = filled + margin:getTop() + margin:getBottom()
      else
        filled = filled + margin:getLeft() + margin:getRight()
      end

      chunks[i] = {const = false, stretch = self._stretch[child], el = child}
      lastMut = i
    end
  end

  return chunks, filled, count, lastMut
end

--- @section end

--- A specialized version of `BoxLayout` that uses a vertical layout direction.
-- @cl VBoxLayout
-- @extends BoxLayout
local VBoxLayout = class(BoxLayout, {name = "wonderful.layout.box.VBoxLayout"})

--- @type VBoxLayout

--- Construct a new instance.
-- @tparam table args keyword argument table
-- @tparam[opt=false] boolean args.reversed whether to set the direction to
-- bottom-to-top
function VBoxLayout:__new__(args)
  args.direction = getVerticalDirection(args.reversed)
  args.reversed = nil

  self:superCall("__new__", args)
end

--- Set the direction in which to lay children out.
--
-- Automatically issues composition request.
--
-- @tparam boolean reversed whether to set the direction to bottom-to-top
function VBoxLayout:setDirection(reversed)
  self:superCall("setDirection", getVerticalDirection(reversed))
end

--- @section end

--- A specialized version of `BoxLayout` that uses a horizontal layout direction.
-- @cl HBoxLayout
-- @extends BoxLayout
local HBoxLayout = class(BoxLayout, {name = "wonderful.layout.box.HBoxLayout"})

--- @type HBoxLayout

--- Construct a new instance.
-- @tparam table args keyword argument table
-- @tparam boolean args.reversed whether to set the direction to right-to-left
function HBoxLayout:__new__(args)
  args.direction = getHorizontalDirection(args.reversed)
  args.reversed = nil

  self:superCall("__new__", args)
end

--- Set the direction in which to lay children out.
--
-- Automatically issues composition request.
--
-- @tparam boolean reversed whether to set the direction to right-to-left
function HBoxLayout:setDirection(reversed)
  self:superCall("setDirection", getHorizontalDirection(reversed))
end

--- @export
return {
  Direction = Direction,
  BoxLayout = BoxLayout,
  VBoxLayout = VBoxLayout,
  HBoxLayout = HBoxLayout,
}

