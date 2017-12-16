local class = require("lua-objects")

local Style = class(nil, {name = "wonderful.style.Style"})

function Style:__new__()
  self.rules = {}
end

function Style.fromBuffer(buffer)
  local str = ""
  while true do
    local chunk = buffer:read()
    if not chunk then
      break
    end
    str = str .. chunk
  end
  return Style.fromString(str)
end

function Style.fromString(str)
  local style = Style()
  -- parse
  return style
end

return {
  Style = Style
}
