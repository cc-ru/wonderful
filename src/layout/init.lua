local class = require("lua-objects")

local Margin = require("wonderful.geometry").Margin

local Layout = class(nil, {name = "wonderful.layout.Layout"})

function Layout:recompose(el)
  error("unimplemented abstract method Layout:recompose")
end

function Layout:sizeHint(el)
  error("unimplemented abstract method Layout:sizeHint")
end

local LayoutItem = class(nil, {name = "wonderful.layout.LayoutItem"})

function LayoutItem:sizeHint()
  return 0, 0
end

function LayoutItem:getMargin()
  return Margin(0, 0, 0, 0)
end

function LayoutItem:getStretch()
  return 0
end

function LayoutItem:boxCalculated(box)
  error("unimplemented abstract method LayoutItem:boxCalculated")
end

local LayoutContainer = class(nil, {name = "wonderful.layout.LayoutContainer"})

function LayoutContainer:getLayoutItems()
  error("unimplemented abstract method LayoutContainer:getLayoutItems")
end

function LayoutContainer:getLayoutPadding()
  error("unimplemented abstract method LayoutContainer:getLayoutPadding")
end

return {
  Layout = Layout,
  LayoutItem = LayoutItem,
  LayoutContainer = LayoutContainer
}

