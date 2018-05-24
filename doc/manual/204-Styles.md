# Styles
## The style engine
The style engine makes it easy to set component properties. You can do this for
a group of elements, and even switch between stylesheets on-the-fly. And you
don't need to hold references to all targeted elements in order to do this.

Keep in mind that style parsing is memory-intensive, and you may get
out-of-memory errors on low-end setups.

By default, a `Document` creates a blank stylesheet. Obsiously, you can set your
own one. The `wonderful.Wonderful:addDocument` method accepts the `style`
named argument, which can be a string, a stream, or a position-aware text
buffer (defined in `wonderful.style.buffer`).

```lua
local wmain = Wonderful()


local document = wmain:addDocument {
  style = io.open("/usr/share/my-program/my-program.wsf", "r")
}
```

If you pass a stream, it'll be closed automatically.

You can get more control over the parsing options by using a style instance.
The `wonderful.style` module exports two similar classes: `Style` and
`WonderfulStyle`. The latter is a `Style` subclass that adds the built-in
properties and selectors (we'll talk about them later). Unless you want to
replace the built-in properties and selectors completely, use `WonderfulStyle`.

There are two ways of constructing an instance: building and initializing.

Building means that you set options by chaining methods, e.g., `addTypes`,
`addVars`, etc. Load the stylesheet when you're done setting parsing options,
using one of the `parse` methods (`parseFromString`, `parseFromStream`, and
others).

```lua
local wstyle = require("wonderful.style")

local components = require("my-program.components")
local myprogram = require("my-program")

local style = wstyle.WonderfulStyle():addTypes({
  Rect = components.Rectangle
}):addProperties({
  test = myprogram.TestProperty
}):parseFromStream(io.open("/usr/share/my-program/style.wsf", "r"))
```

It's worth noting that `parseFromStream` automatically closes the passed stream.

The same instance can be created by setting parsing options when instanciating:
You pass them to the constructor as named arguments.

```lua
local wstyle = require("wonderful.style")

local components = require("my-program.components")
local myprogram = require("my-program")

local style = wstyle.WonderfulStyle {
  types = {
    Rect = components.Rectangle
  },
  properties = {
    test = myprogram.TestProperty
  },
  stream = io.open("/usr/share/my-program/style.wsf", "r")
}
```

The returned instance will contain the interpreter context (the AST, variables,
types, and so on) by default. It allows the instance to be imported in other
stylesheets, but it also consumes quite a lot of memory. To strip the context
information, use `stripContext` method.

You can make the document use the instance by setting the `style` named
argument.

```lua
local wmain = Wonderful()
local document = wmain:addDocument {
  style = WonderfulStyle {
    types = {
      Rect = components.Rectangle
    },
    properties = {
      test = myprogram.TestProperty
    },
    stream = io.open("/usr/share/my-program/style.wsf", "r")
  }:stripContext()
}
```

## Using the style engine
**TODO**

## The style language
Basically, a style file is a list of statements. All statements end with
a semicolon.

Look at the example below.

```
<wonderful.component.button:Button> {
  background-color: #20afff;
  color: #ffffff;
};
```

This is a rule statement, the most important statement in the language,
which actually sets some properties to some values.

Note that there's a semicolon after the closing brace.

Every rule statement consists of a target specification and a list of
properties. The list is enclosed in braces, and each entry is terminated with
a semicolon. The property name is separated from its value with a colon.

The target specification describes components the rule applies to. It consists
of one or more *targets*, separated with commas. In the example, there's only
one target: `<wonderful.component.button:Button>`.

There are many ways to declare a target. The most basic one is to specify
a *type*. In the style language terms, this is an identifier of a class (or
classes if you're not careful enough!). Yet again, there are several ways to
specify a type.

* `<module:name>` equals to `require("module")["name"]`, and resolves to
  a class unambiguously. Prefer this option if the class can be require'd.
* `<"/path/to/file.lua":name>` equals to `dofile("/path/to/file.lua")["name"]`.
  Unlike a module, the file is **not** cached, and is reloaded every time the
  interpreter sees this specifier.
* `[ClassName]` matches all components whose class name attribute is set to
  "ClassName". This can be used for your one-file programs that are not
  supposed to be `require`'d. But you must make sure the class names stay
  unique.
* `*` is a special one. It matches any component.
* `@TypeRef` is a type reference. We'll talk about them a bit later.

Imagine that you have two buttons—"Ok" and "Cancel"—and you want to make the
"Ok" button green, and paint the other button in red. You can't simply use
a type, such as `<wonderful.component.button:Button>`, since it will match
the both buttons...

Classes come to the rescue! This may be really confusing, but the classes I mean
are not the classes in OOP sense; instead, they're more like some kind of tags
that you can use to mark components; e.g., you set a "blue" class on a bunch of
components, and in the style file, you can match them and set `color` to `#00f`
(each digit is doubled, so `#00f` means `#0000ff`, and `#123` means `#112233`).
Anyway, back to the example.

```
.ok {
  background-color: #0f0;
};

.cancel {
  background-color: #f00;
};
```

When creating the buttons, set the `wonderful.element.attribute.Classes`
attribute to `{"ok"}` for the "Ok" button, and `{"cancel"}` for the other one.
If you apply the style above, the "Ok" button will be green, and the "Cancel"
button will be red, just like we wanted.

You may combine the classes in the specification. Take a look at another
example. If a component has both the "blue" and "black" classes set, it will be
painted in dark blue.

```
.blue.black {
  background-color: #114;
};
```

You can also combine the type and the class list in the specification. Just keep
in mind that the type must come first.

```
<wonderful.component.button:Button>.ok {
  background-color: #080;
  color: #fff;
};
```

**TODO: selectors**

Now, what if you don't care about any of the classes, types, or whatever, and
just want to set a property for every single GUI element? All elements that
compose a target are omittable, so you may think about doing something like
this:

```
{
  color: #fff;
};
```

As you can guess, it will result a syntax error. To be valid, a target must
have at least one specifier. Remember the `*` type, which matches all elements.
This is when you should use it.

```
* {
  color: #fff;
};
```

Ta-da! All the text is set to white. Truly wonderful.

Ah, while we are speaking about types. Writing out the types every time may
become really tedious.

```
<wonderful.component.button:Button> {
  color: #fff;
  background-color: #888;
};

<wonderful.component.button:Button>.ok {
  background-color: #080;
};

<wonderful.component.button:Button>.cancel {
  background-color: #800;
};
```

Uhh, typing the types wasn't fun at all. Thankfully, you can avoid this.
Introducing: a type alias statement!

```
//   +- the alias name
//   |        +- the type
//   v        v
type Button = <wonderful.component.button:Button>;

// and here we use the alias instead, prefixed with `@`
@Button {
  color: #fff;
  background-color: #888;
};

@Button.ok {
  background-color: #080;
};

@Button.cancel {
  background-color: #800;
};
```

As you can see, it's all clean and tidy now. Oh, the lines starting with `//`
are comments: The interpreter ignores everything that comes after the slashes
until the end of the line. There are multiline comments, too:

```
/* a
           multiline
comments
  are supported,
   too! */

.green /* not really multiline but still works */ {
  color: #0f0;
};
```

A fun fact: Although the type references are erased by the interpreter in the
end, they can serve as a type, so, technically, nothing stops you from doing
this:

```
type A = <wonderful.component.button:Button>;
type B = @A; // resolves to <wonderful.component.button:Button>
```

Well, what you should do with it is up to you.

```
* {
  color: #ccc;
};

.ok {
  color: #fff;
  background-color: #080;
};

.cancel {
  background-color: #800;
  color: #fff;
};

.update-button {
  color: #fff;
};

// and so on
```

Do you see the problem in the example above? You have to manually keep track
of the used color palette. Changing all the colors is also a problem.

You can make your stylesheet better by using variables.

```
primary-fg = #fff;
primary-bg = #333;
fg = #ccc;

red = #800;
green = #080;

* {
  color: $fg;
};

.ok {
  color: $primary-fg;
  background-color: $green;
};

.cancel {
  color: $primary-fg;
  background-color: $red;
};

.update-button {
  color: $primary-fg;
  background-color: $primary-bg;
};
```

As you can see, a variable is referenced by writing `$` and its name. The
interpreter then replaces the variable reference with its contents; e.g.,
`"test" $primary-bg "test"` becomes `"test" #333 "test"`.

Well, there's one last statement in the language—the import statement. It
imports **public** variables, type aliases, and rules from other context into
the current one.

All variables, type aliases and rules are **private** by default. You have to
explicitly make them public by prefixing the statements with a `pub` keyword:

```
pub type Button = <wonderful.component.button:Button>;

pub green = #00ff00;

pub .green {
  color: $green;
};
```

Now it's ready to be imported. The following example lists all the different
options you have for importing styles:

```
// 1. Imports from other file
import "/path/to/file.wsf";

// 2. Imports from an already parsed style instance
// 2.1. In a module
import <module:style>;

// 2.2. Passed by reference (by using `addTypes`, for example)
import @StyleInstance;
```

In 2.1 or 2.2, you can pass it either a `Context` or a `Style` instance that
doesn't have its context stripped.

You can use imports to organize your styles. You can create a file called
`palette.wsf` that sets a bunch of color variables, another one called
`types.wsf` that adds aliases for all the used components, and import them in
the main style file, which is then loaded.

Or, perhaps, make two files—`dark.wsf` and `light.wsf`—which set the colors,
and put the things shared by both into `common.wsf`. Then you can toggle the
theme by pressing a button in the UI, for example.

**TODO: expressions**
