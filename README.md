We're building a new GUI library for OpenComputers. Here's how it's going to be
different from other libraries:

- **Multi-monitor setup support.** Any setup will be supported.
- **Advanced event system.** Event handlers are called in the top-to-bottom
  order, and any handler can stop the event from descending.
- **Styles.** No need to touch the code if you feel that your green color isn't
  green enough: just change a variable in your style file.
- **Layouts.** Why calculate the position yourself if the computer can do it
  just as well, and even better?
- **Customization and extendability.** To modify a component, just extend from
  another one. Inherit from the base class `wonderful.element.Element` if
  you want to implement it from scratch.
- **Buffered rendering.** The library only issues GPU calls for the parts that
  changed since the previous update, and packs them together beforehand.
- **OOP.** I mean, proper OOP. Multi-inheritance, getters and setters, and
  more—thanks to the lua-objects library.

The manual pages and API reference are available on
[doc.fomalhaut.me](http://doc.fomalhaut.me/wonderful/).
