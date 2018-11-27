<h1 align="center">wonderful</h1>
<div align="center"><em>A wonderful GUI library for OpenComputers</em></div>

Features:

- **Multi-monitor setup support.** Any setup will be supported.
- **Advanced event system.** Allows to implement and override behavior of any
  element.
- **Layouts.** Why calculate the position yourself if the computer can do it
  just as well, and even better?
- **Customization and extendability.** To modify a component, just extend from
  another one. Inherit from the base class `wonderful.element.Element` if
  you want to implement it from scratch.
- **Buffered rendering.** The library only issues GPU calls for the parts that
  changed since the previous update, and packs them together beforehand.
- **OOP.** I mean, proper OOP. Multi-inheritance, getters and setters, and
  more — thanks to the lua-objects library.

## Documentation
The manual pages and API reference are available on
[doc.fomalhaut.me](https://doc.fomalhaut.me/wonderful/).

## Current state
I've been building the library for almost a year (wow), and am still quite far
from getting it done.

The library consists of 4 parts, each packaged separately:
- `wonderful-common`, common utilities used by other parts
- `wonderful-buffer`, the render buffer
- `wonderful-core`, the GUI core
- `wonderful-std`, the provided-by-default collection of something (hopefully
  widgets).

As for now, only `common` and `buffer` got their `0.1.0` releases; other
parts have yet to be released.

Visit the [issue tracker](https://github.com/cc-ru/wonderful/issues) for the
list of tasks.

I have to admit that this project is only barely alive. It's not yet dead,
though.

## Installation
Want to tinker with the library nonetheless? Here's how to install wonderful.

- On your opencomputer, fetch the code (you may directly run `git clone` there,
  for example, or download the code manually).
- Install `hpm` if you haven't already: `pastebin run vf6upeAN`. Despite it's
  no longer maintained, I still use it for installing.
- Run the following commands:

```
# hpm install -ly ./common
# hpm install -ly ./buffer
# hpm install -ly ./core
# hpm install -ly ./components
# hpm install -ly .
```

## Development and contributing
I use the GitHub issues to manage the work. I also have the
[GitHub project](https://github.com/cc-ru/wonderful/projects/1). The "To do"
list there is ordered; things at the top should probably be done first. Though
there are also things worth doing anytime, and the documentation is a notable
example.

Contributing code to the library can be difficult, as most things are
basically undocumented, only having a LuaDoc. You need to understand how the
most of the codebase works by reading the source code, although there are a few
examples to help you out. If you want to ask questions about the library, feel
free to reach out to me:

- On the IRC: fingercomp at `irc.esper.net`
- On the [OpenComputers forums](https://oc.cil.li)
- By opening an issue here and stating the question

I highly appreciate documentation contributions. Creating a new manual page,
updating the pages that already exist, or fixing a simple typo — it doesn't
really matter how small or big a contribution is.

## License
The code is licensed under the Apache License, Version 2.0. All examples are
available under the Unlicense (see the `examples` directory).
