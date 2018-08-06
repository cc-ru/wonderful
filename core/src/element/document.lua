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

local attribute = require("wonderful.element.attribute")
local element = require("wonderful.element")
local focus = require("wonderful.element.focus")
local signal = require("wonderful.signal")
local style = require("wonderful.style")
local textBuf = require("wonderful.style.buffer")

--- The document class.
-- The root element of a render tree.
-- @see wonderful.element.Element
local Document = class(
  element.Element,
  {name = "wonderful.element.document.Document"}
)

--- The document class.
-- The root element of a render tree.
-- @type Document

--- Construct a new document.
-- @tparam table args a keyword argument table
-- @tparam[opt] wonderful.style.Style|wonderful.style.buffer.Buffer|{["read"]=function,...}|string args.style a style instance, or a text buffer or input stream or string to parse and use as a style for the document
-- @tparam wonderful.display.Display args.display a display
function Document:__new__(args)
  self:superCall(element.Element, "__new__")

  if type(args.style) == "table" and args.style.isa and
      args.style:isa(style.Style) then
    self.globalStyle = args.style
  elseif type(args.style) == "table" and args.style.isa and
      args.style:isa(textBuf.Buffer) then
    self.globalStyle = style.WonderfulStyle()
                            :parseFromBuffer(args.style)
                            :stripContext()
  elseif type(args.style) == "table" and args.style.read then
    self.globalStyle = style.WonderfulStyle()
                            :parseFromStream(args.style)
                            :stripContext()
  elseif type(args.style) == "string" then
    self.globalStyle = style.WonderfulStyle()
                            :parseFromString(args.style)
                            :stripContext()
  else
    self.globalStyle = style.WonderfulStyle()
  end

  self.globalDisplay = args.display

  self.calculatedBox = self.globalDisplay.box

  self:addDefaultListener({
    event = signal.KeyDown,
    handler = self.onKeyDown,
  })
end

function Document:render(view)
  view:fill(1, 1, view.w, view.h, 0xffffff, 0x000000, 1, " ")
end

function Document:onKeyDown(e)
  if e.code == kbd.keys.tab then
    if kbd:isShiftDown(e.keyboard) then
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
  local prev = self.focused

  local traversalFunc

  if reversed then
    traversalFunc = self.rlnWalk
  else
    traversalFunc = self.nlrWalk
  end

  local found = not prev

  local new = traversalFunc(self, function(node)
    if found and node:get(attribute.Focus, true).enabled then
      return node
    end

    if prev == node then
      found = true
    end
  end)

  if prev then
    prev.focused = false
  end

  if new then
    new.focused = true
  end

  self.focused = new

  if prev then
    if prev:dispatchEvent(focus.FocusOut(new)) then
      -- the event was canceled
      prev.focused = true
      new.focused = false
      self.focused = prev

      return false
    end
  end

  if new then
    if new:dispatchEvent(focus.FocusIn(prev)) then
      -- the event was canceled
      prev.focused = true
      new.focused = false
      self.focused = prev

      return false
    end
  end

  return true
end

function Document.__getters:focusingContext()
  return self.rootFocusingContext
end

function Document.__getters:viewport()
  return self.calculatedBox
end

return {
  Document = Document
}

