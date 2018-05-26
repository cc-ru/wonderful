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
local LayoutItem = require("wonderful.layout").LayoutItem

--- The enum of directions in which children can be layed out.
local Direction = {
  TopToBottom = 0,  --- The first child is at the top, consequent ones are put below it.
  BottomToTop = 1,  --- The first child is at the bottom, consequent ones are put above it.
  LeftToRight = 2,  --- The first child is at the left, consequent ones are put to the right of it.
  RightToLeft = 3,  --- The first child is at the right, consequent ones are put to the left of it.
}

--- The box layout.
local BoxLayout = class(Layout, {name = "wonderful.layout.box.BoxLayout"})

--- The box layout.
-- @type BoxLayout

--- The direction in which the layout children are layed out.
-- @field BoxLayout.direction

--- Construct a new instance.
-- @tparam number direction a direction in which to lay children out
-- @see wonderful.layout.box.Direction
function BoxLayout:__new__(direction)
  self.direction = direction
end

--- Recompose the layout children.
-- @param el a container element
function BoxLayout:recompose(el)
  -- Do not touch. For the sake of your own sanity.
  -- TODO: handle BTT and RTL directions
  -- TODO: refactor into smaller functions

  local chunks = {}
  local i = 0
  local filled = 0
  local count = 0
  local lastMut = 0

  local vertical = self.direction == Direction.TopToBottom
                or self.direction == Direction.BottomToTop
  local reversed = self.direction == Direction.RightToLeft
                or self.direction == Direction.BottomToTop

  for _, child in ipairs(el:getLayoutItems()) do
    if child:getStretch() == 0 then
      local w, h = child:sizeHint()
      local margin = child:getMargin()

      if not chunks[i] or not chunks[i].const then
        i = i + 1
        chunks[i] = {const = true}
      end

      table.insert(chunks[i], child)

      if vertical then
        filled = filled + h + margin.t + margin.b
      else
        filled = filled + w + margin.l + margin.r
      end
    else
      local margin = child:getMargin()

      i = i + 1
      count = count + child:getStretch()

      if vertical then
        filled = filled + margin.t + margin.b
      else
        filled = filled + margin.l + margin.r
      end

      chunks[i] = {const = false, stretch = child:getStretch(), el = child}
      lastMut = i
    end
  end

  local box = el:getLayoutBox()
  local pad = el:getLayoutPadding()

  local full = vertical and
               (box.h - pad.t - pad.b) or
               (box.w - pad.l - pad.r)

  local basis = (full - filled) / count
  local x, y = box.x + pad.l, box.y + pad.t

  for j, chunk in ipairs(chunks) do
    if chunk.const then
      for _, el in ipairs(chunk) do
        local w, h = el:sizeHint()
        local margin = el:getMargin()

        if reversed and vertical then
          el:boxCalculated(Box(x + margin.l,
                               full - y + margin.b - h,
                               w,
                               h))
        elseif reversed then
          el:boxCalculated(Box(full - x - margin.r - w + margin.l,
                               y + margin.t,
                               w,
                               h))
        else
          el:boxCalculated(Box(x + margin.l,
                               y + margin.t,
                               w,
                               h))
        end

        if vertical then
          y = y + h + margin.t + margin.b
        else
          x = x + w + margin.l + margin.r
        end
      end
    else
      local el = chunk.el

      local w, h = el:sizeHint()
      local margin = el:getMargin()

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
        el:boxCalculated(Box(x + margin.l,
                             full - y + margin.b - h,
                             w,
                             h))
      elseif reversed then
        el:boxCalculated(Box(full - x - margin.r - w + margin.l,
                             y + margin.t,
                             w,
                             h))
      else
        el:boxCalculated(Box(x + margin.l,
                             y + margin.t,
                             w,
                             h))
      end

      if vertical then
        filled = filled + h
        y = y + h + margin.t + margin.b
      else
        filled = filled + w
        x = x + w + margin.l + margin.r
      end
    end
  end
end

--- Estimate a size of an element and its children.
-- @treturn number the width
-- @treturn number the height
function BoxLayout:sizeHint(el)
  local width, height = 0, 0

  local vertical = self.direction == Direction.TopToBottom or
                   self.direction == Direction.BottomToTop

  for _, child in ipairs(el:getLayoutItems()) do
    local hw, hh = child:sizeHint()
    local margin = child:getMargin()

    if vertical then
      width = math.max(width, hw)
      height = height + hh + margin.t + margin.b
    else
      height = math.max(height, hh)
      width = width + hw + margin.l + margin.r
    end
  end

  return width, height
end

---
-- @section end

--- A specialized version of `BoxLayout` that uses a vertical layout direction.
-- @see wonderful.layout.box.BoxLayout
local VBoxLayout = class(BoxLayout, {name = "wonderful.layout.box.VBoxLayout"})

--- A specialized version of `BoxLayout` that uses a vertical layout direction.
-- @type VBoxLayout

--- Construct a new instance.
-- @tparam boolean reversed whether to set the direction to bottom-to-top
function VBoxLayout:__new__(reversed)
  self:superCall(BoxLayout, "__new__",
                 reversed and Direction.BottomToTop or Direction.TopToBottom)
end

---
-- @section end

--- A specialized version of `BoxLayout` that uses a horizontal layout direction.
-- @see wonderful.layout.box.BoxLayout
local HBoxLayout = class(BoxLayout, {name = "wonderful.layout.box.HBoxLayout"})

--- A specialized version of `BoxLayout` that uses a horizontal layout direction.
-- @type HBoxLayout

--- Construct a new instance.
-- @tparam boolean reversed whether to set the direction to right-to-left
function HBoxLayout:__new__(reversed)
  self:superCall(BoxLayout, "__new__",
                 reversed and Direction.RightToLeft or Direction.LeftToRight)
end

---
-- @export
return {
  Direction = Direction,
  BoxLayout = BoxLayout,
  VBoxLayout = VBoxLayout,
  HBoxLayout = HBoxLayout,
}

