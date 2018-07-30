For the half of the year of 2018, and the second half of December 2017, we've
been building the ultimate, the **wonderful** GUI library. What's included?

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

The manual pages and API reference are available on
[doc.fomalhaut.me](http://doc.fomalhaut.me/wonderful/). Ignore the certificate
problems: we couldn't make the hoster include the doc subdomain.
