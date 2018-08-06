std = "lua53"
color = true
codes = true

read_globals = {
  "checkArg",
  os = {
    fields = {
      "sleep"
    }
  }
}

include_files = {
  "common/src/**",
  "buffer/src/**",
  "core/src/**",
  "components/src/**",
  "examples/**/*.lua",
}

max_code_line_length = 80
max_string_line_length = 80
max_comment_line_length = false
ignore = {"212"}
