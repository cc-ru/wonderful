
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

--- The relative layout.
-- @module wonderful.layout.box

local class = require("lua-objects")

local Layout = require("wonderful.layout").Layout

--- The relative layout.
-- @cl RelativeLayout
-- @extends wonderful.layout.Layout
local RelativeLayout = class(
  Layout,
  {name = "wonderful.layout.relative.RelativeLayout"}
)

-- @type RelativeLayout

--- Construct a new instance.
-- @tparam table args keyword argument table
function RelativeLayout:__new__(args)
  args = args or {}

  self:superCall("__new__", args)

  -- This is a two-dimensional child vector that stores their position and
  -- width.
  --
  -- Since the list is homogeneous, we can and do flatten the list and store the
  -- data is the following way.
  --
  -- self._positions[element] returns the index `k` such that:
  --
  -- - self._positions[k + 1] >> 8 is the column of `element`
  -- - self._positions[k + 1] & 0xff is the row of `element`
  -- - self._positions[k + 2] is the width of `element` (or `nil` if unset)
  -- - self._positions[k + 3] is the width of `element` (or `nil` if unset)
  --
  -- Note that we don't actually use the `>>` and `&` operators here to avoid
  -- making the code specific to Lua 5.3, doing instead:
  --
  -- - `math.floor(self._positions[k + 1] / 256)` to get the column of `element`
  -- - `self._positions[k + 1] % 256` to get the row of `element`
  --
  -- We don't use the `Node`'s indeces because they shift when an element is
  -- removed. This table does not.
  self._positions = {}
end

--- Insert an element at given **relative** coordinates.
--
-- If the width is unset, it defaults to `width - x + 1`, where `width` is the
-- width returned by calling `element:sizeHint()`. The behavior of height is
-- analogous.
--
-- @tparam int x the column at which to put the element
-- @tparam int y the row at which to put the element
-- @tparam[opt] int width the width of the element
-- @tparam[optchain] int height the height of the element
-- @param element the element
function RelativeLayout:insertChild(x, y, width, height, element)
  if not height then
    -- :insertChild(x, y, element)
    element = width
    width, height = nil, nil
  elseif not element then
    -- :insertChild(x, y, width, element)
    element = height
    height = nil
  end

  local lastIndex = #self._positions
  local index = math.floor((lastIndex + 2) / 3) * 3 + 1

  -- How the index is calculated:
  --        a =  0  1  2  3  4  5  6  7  8  9  10 11 12
  --  b = a + 2  2  3  4  5  6  7  8  9  10 11 12 13 14
  -- c = c // 3  0  1  1  1  2  2  2  3  3  3  4  4  4
  --  d = c * 3  0  3  3  3  6  6  6  9  9  9  12 12 12
  --  i = d + 1  1  4  4  4  7  7  7  10 10 10 13 13 13
  --
  -- so index i = (lastIndex + 2) // 3 * 3 + 1

  self:superCall("insertChild", element)

  -- this is (y << 8) | x
  self._positions[index + 1] = y * 256 + x

  self._positions[index + 2] = width
  self._positions[index + 3] = height
  self._positions[element] = index

  self:requestComposition()
end

--- Remove an element from the layout.
-- @param element the element
-- @return[1] the removed element
-- @treturn[2] `false` no such element
function RelativeLayout:removeChild(element)
  local index = self._positions[element]

  if not index then
    return false
  end

  self:superCall("removeChild", element)

  self._positions[index + 1] = nil
  self._positions[index + 2] = nil
  self._positions[index + 3] = nil
  self._positions[element] = nil

  self:requestComposition()
end

--- Replace an element with another one, optionally changing the position
-- settings.
--
-- If the method is called as `layout:replaceChild(element1, element2)`, the
-- position settings are left unchanged.
--
-- Otherwise, the method assumes it's called as
-- `:replaceChild(element1, element2, x, y, [width[, height]])` and changes the
-- position settings accordingly.
--
-- @param element1 the element to remove
-- @param element2 the element to replace with
-- @tparam int x the column at which to put the element
-- @tparam int y the row at which to put the element
-- @tparam[opt] int width the width of the element
-- @tparam[optchain] int height the height of the eleemnt
-- @return[1] the removed element
-- @treturn[2] `false` `element1` is not contained in the layout
function RelativeLayout:replaceChild(element1, element2, x, y, width, height)
  local index = self._positions[element1]

  if not index then
    return false
  end

  if not x then
    x, y, width, height = self:_getPositionData(element1)
  end

  self:superCall("replaceChild", element)

  self._positions[index + 1] = y * 256 + x
  self._positions[index + 2] = width
  self._positions[index + 3] = height
  self._positions[element1] = nil
  self._positions[element2] = index

  self:requestComposition()
end

-- Get the position settings about an element.
--
-- Assumes the element is an child of the layout.
--
-- @param element the element
-- @treturn int x the column
-- @treturn int y the row
-- @treturn ?int width
-- @treturn ?int height
function RelativeLayout:_getPositionData(element)
  local index = self._positions[element]
  local yx = self._positions[index + 1]

  return yx % 256,
         math.floor(yx / 256),
         self._positions[index + 2],
         self._positions[index + 3]
end

function RelativeLayout:_compose(box)
  for child in self:getChildren() do
    local x, y, width, height = self:_getPositionData(child)
    local shWidth, shHeight = child:sizeHint()

    width = width or shWidth
    height = height or shHeight

    child:getBoundingBox():setBox(box:relative(x, y, width, height))
  end
end

function RelativeLayout:sizeHint()
  local width, height = 0, 0

  for child in self:getChildren() do
    local x, y, childWidth, childHeight = self:_getPositionData(child)
    local shWidth, shHeight = child:sizeHint()

    childWidth = childWidth or shWidth
    childHeight = childHeight or shHeight

    width = math.max(width, x + childWidth - 1)
    height = math.max(height, y + childHeight - 1)
  end

  return width, height
end

--- @export
return {
  RelativeLayout = RelativeLayout,
}
