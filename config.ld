project = 'wonderful'
title = 'wonderful documentation'
description = 'The *wonderful* GUI library.'
full_description = [[
This is the API reference for the wonderful library.

Also see @{000-Home.md|the manual} pages.]]

examples = 'examples'

topics = 'doc/manual'
use_markdown_titles = true

file = {
  'buffer/src',
  'core/src',
  'common/src',
  'std/src'
}

dir = 'doc/html/'

kind_names = {
  topic = 'Manual',
}

format = 'discount'
no_space_before_args = true
convert_opt = true
wrap = true
sort_modules = true

new_type('cl', 'Classes and inheritance', false)

custom_tags = {
  {'extends', title = 'Parent classes', hidden = false,
   format = function(value)
     return typename(value)
   end}
}
