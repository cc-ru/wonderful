# Lua
Indent with **2 spaces**. Don't use tabs. Indent:
* Body of `if`/`elseif`/`else`/`end`, `for`/`end`, `while`/`end`, `do`/`end`,
  `function`/`end`, `repeat`/`until`.
* Body of table literals if every element starts from the new line.
* Contents of parenthesis if the first element starts from the new line.

```lua
if true then
  ...
elseif false then
  ...
else
  ...
end

function rip()
  ...
end

do
  ...
end

while true do
  ...
end

for ... do
  ...
end

repeat
  ...
until true

tbl = {
  1,
  2,
  3
}
```

Hang-indent (indent to a character following the opening bracket/brace):
* Body of table literals if the first element is on the same line as the
  brace (multiple items per line allowed).
  * The closing brace **must not** be newlined.
* Contents of parenthesis if the first element is on the same line as the
  opening bracket (multiple items per line allowed).
  * The closing bracket **must not** be newlined.

```lua
local tbl = {1, 2, 3,
             4, 5, 6,
             7, 8, 9}
func(1, 2, 3, 4,
     5, 6, 7, 8)
```

Don't add spaces between brackets and the content.

Always newline the body of structures (`if`, `for`, etc.).

```lua
-- DO NOT
if true then print() end

-- DO
if true then
  print()
end
```

All structures must start from a new line. The only exception is `do` if the
body defines the variable forward-declared before.

```lua
...
if true do
  ...
end
...
local var do
  var = function() end
end
```

Leave the last line of a file blank.

Sort requires alphabetically. Separate the three groups of requires with blank
lines:

* OpenOS / Lua libraries (`component`, `term`).
* User libraries (stored in `/usr/lib/`, installed using a package manager).
* Program's own modules.

The code following the imports must be separated with a newline.

```lua
local com = require("component")
local comp = require("computer")

local class = require("lua-objects")

local style = require("wonderful.style")

...
```

Do not insert two and more newlines in row.

Do not create global variables. Make all variables local.

Choose meaningful names for variables.

* Name top-scope constants and enum keys in `UPPER_SNAKE_CASE`.
* Name variables, functions, table keys in `lowerCamelCase`.
* Name classes in `UpperCamelCase`.
* Name modules in `kebab-case`.

Don't include 'a' or 'the' in the names. Don't use Hungarian notation.

```lua
-- DO NOT
local bAHoleInTheWall = true

-- DO
local holeInWall = true
```

Put:

* a space **before** and a space **after** `+`, `-`, `*`, `/`, `%`, `&`, `~`,
  `|`, `<<`, `>>`, `//`, `==`, `~=`, `>`, `>=`, `<`, `<=`, `=`, `..`; `and`,
  `or`, `in`
* a space **before**: `#`
* a space **after**: `;`, `,`
* no spaces around: `:`, `.`, `[`, `]`, `(`, `)`, `{`, `}`, `::`

When commenting an element of a table on the same time, put **two spaces**
before the comment. In other cases, do not put two or more spaces between
tokens.

```
local greatness = {
  1,  -- good
  2,  -- great
  3,  -- wonderful
}
```

Don't leave out parenthesis in function calls. The only exception is table
literals when used as an argument table; add a space between the literal and
the function name.

```lua
func("test")
func({1, 2, 3})
func {x = 1, y = 2}
```

Write comments for complicated code only, or to separate blocks of code in a
long function. Keep in mind that documentation is written in the wiki.

Limit the code width to 80 columns.

Do not append the semicolon (`;`) to the end. Only use it to delimit sections
in tables.

```lua
local tbl = {1, 2, 3;
             4, 5, 6;
             7, 8, 9}
```

Do not shadow-name variables, including the standard libraries. Do not name
function parameters the same as the standard libraries, though you may
shadow-name variables in the scopes above.

If the module return statements is specified as a table literal, a comma must
be appended to the last element.

```
return {
  A = A,
  B = B,
}
```

# Git
When writing commit messages, write verbs in the infinitive form.

```
# DO NOT:
Created a new file
Creates a new file

# DO:
Create a new file
```

GitHub commit keywords, like `closes` and `fixes`, must be written in the
third-person form.

```
# DO NOT:
Create a new file. Close #5.

# DO:
Create a new file. Closes #5.
```

Start from the capital letter. Don't put full stop at the end if the message
is one-sentence-long.

```
# DO NOT:
create a new file.
create a new file. closes #5

# DO:
Create a new file
Create a new file. Closes #5.
```

If the origin rejects your commits because someone else pushed their commits
earlier, pull the changes using `git pull --rebase`. Don't forget the `--rebase`
flag, or you'll be creating a merge commit instead even when not necessary.

Don't force-push.

When merging branches, do `git merge --no-ff`.
