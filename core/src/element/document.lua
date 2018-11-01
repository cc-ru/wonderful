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

--- The @{wonderful.element.document.Document|Document} class.
-- @module wonderful.element.document

local class = require("lua-objects")

local kbd = require("keyboard")

local focus = require("wonderful.std.event.focus")
local signal = require("wonderful.std.event.signal")

local Layout = require("wonderful.layout").Layout
local Widget = require("wonderful.widget").Widget

--- The document class.
--
-- The root element of a render tree.
--
-- The document is a layout that has a single child. On composition, that child
-- is provided with the whole area of the document. One would usually set
-- another layout (e.g. a box) as the child to allow for the most flexibility.
--
-- @cl Document
-- @extends wonderful.layout.Layout
local Document = class(
  Layout,
  {name = "wonderful.element.document.Document"}
)

--- @type Document

--- Construct a new document.
-- @tparam table args a keyword argument table
-- @tparam wonderful.display.Display args.display a display
function Document:__new__(args)
  self:superCall(Layout, "__new__", args)

  self._globalDisplay = args.display
  self._elementFocused = nil

  self:getBoundingBox():setBox(self._globalDisplay:getBox())

  self:addDefaultListener {
    event = signal.KeyDown,
    handler = self.onKeyDown,
  }
end

function Document:onKeyDown(e)
  if e:getCode() == kbd.keys.tab then
    if kbd:isShiftDown(e:getKeyboard()) then
      self:switchFocus(true)
    else
      self:switchFocus(false)
    end
  end
end

--- Switch focus to the next (or previous) element in the focusing context.
--
-- Usually called by pressing `Tab` / `Shift-Tab`.
--
-- The focused element does not change if the events sent get canceled.
--
-- @tparam boolean reversed if true, switches to the previous element
-- @treturn boolean whether the focus was actually switched
function Document:switchFocus(reversed)
  local prev = self._elementFocused

  local traversalFunc

  if reversed then
    traversalFunc = self.rlnWalk
  else
    traversalFunc = self.nlrWalk
  end

  local found = not prev

  local new = traversalFunc(self, function(node)
    if found and node:isa(Widget) and node.focusable:isEnabled() then
      return node
    end

    if prev == node then
      found = true
    end
  end)

  if prev then
    prev._focused = false
  end

  if new then
    new._focused = true
  end

  self._elementFocused = new

  if prev and prev:dispatchEvent(focus.FocusOut(new)) or
      new and new:dispatchEvent(focus.FocusIn(prev)) then
    -- the event was canceled
    prev._focused = true
    new._focused = false
    self._elementFocused = prev

    return false
  end

  return true
end

--- Set the child of the document.
-- @param element the child element
-- @return[1] the previously set child
-- @treturn[2] `nil` the document had no child
function Document:insertChild(element)
  local previousChild = nil

  if self:hasChildren() then
    previousChild = self:removeChild()
  end

  self:superCall("insertChild", 1, element)

  self:requestComposition()

  return previousCHild
end

--- Remove the child of the document.
-- @return[1] the removed element
-- @treturn[2] `nil` the docuemnt had no child
function Document:removeChild()
  self:superCall("removeChild", 1)
end

function Document:_compose(layoutBox)
  for child in self:getChildren() do
    child:_setBoundingBox(layoutBox)
  end
end

function Document:getDisplay()
  return self._globalDisplay
end

function Document:sizeHint()
  local box = self._globalDisplay:getBox()

  return box:getWidth(),
         box:getHeight()
end

function Document:isFocused(element)
  return self._elementFocused == element
end

--- @export
return {
  Document = Document
}

