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

local element = require("wonderful.element")
local display = require("wonderful.display")
local style = require("wonderful.style")
local textBuf = require("wonderful.style.buffer")

local StackingContext = require("wonderful.element.stack").StackingContext

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

  self.rootStackingContext = StackingContext()
  self.rootStackingContext:insertStatic(1, self)

  self.calculatedBox = self.globalDisplay.box
end

function Document:render(view)
  view:fill(1, 1, view.w, view.h, 0xffffff, 0x000000, 1, " ")
end

function Document.__getters:stackingContext()
  return self.rootStackingContext
end

function Document.__getters:viewport()
  return self.calculatedBox
end

return {
  Document = Document
}

