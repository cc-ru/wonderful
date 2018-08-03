# Home
Wonderful is a *wonderful* GUI library for OpenComputers.

### Why we created it
We were writing a program that needed to display a GUI on multiple screens. But there was no library that
supported multi-screen or multi-GPU setups. Patching a library to make it work with such setups was not
an option: It required making changes to the architecture (in other words, effectively rewriting the library).

We realized we needed to create our own library. So, we started collecting ideas and discussing
the architecture. With a few thousand lines of code pushed to the codebase, the library core was created.

### Differences from other libraries
Or "Key features." Well, some of them are listed in the README, so let's describe each one.

#### Multi-monitor setup support
As said above, the library was created with multi-monitor support in mind. We support any setups you can
possibly imagine... Given that at least one GPU and screen are available, of course—after all, it doesn't
make much sense to use a GUI library if there's no device to draw the UI to!

The renderer uses a GPU pool and draws with an available GPU to minimize the delays.

#### Buffered output
Changes aren't pushed directly to the screen—they are stored in a buffer. When you call `Document:render()`,
the renderer compares it with what's drawn on the screen, optimizes the calls, and outputs to screen.

#### Advanced event system
Handlers are called in the top-to-bottom order if it makes sense (like click handlers). For other events,
we use the child-to-parent order.

Events are cancellable. Any handler can stop an event from ascending the tree, as well as prevent calling other
handlers defined for the same element.

Ah, right! You can add several handlers to the same element and event if you feel like doing so.

We also separate class-defined (default) and instance-defined handlers. So you can safely register a default
handler to make your button flicker, and then defined a click handler—both will be called unless told not to.

#### Styles
The styling engine allows you to separate the layout (element tree and geometry) and the looks (like colors).
The style language supports importing other style files and setting variables.

You can create a file `light.wsf`:

```
[wonderful.component.button.Button] {
  color: #00ff00;
}
```

And `colors-dark.wsf`:

```
[wonderful.component.button.Button] {
  color: #00a090;
}
```

And then switch between them (when clicked on a button, for example): Buttons would change its color from
bright green to dark green.

#### Layouts
A layout provides a way to position their children. It calculates the geometry of its children so you
needn't specify the position yourself.

#### Extendability and customization
You can update the default looks using styles. If you need to go beyond that, you can modify a component
by extending from it.

What about creating your own component? That's easy, too: You just need to extend from our base component class,
`Element` in `wonderful.element`.

The same goes with layouts, styles... Literally everything in the library.

## Get started
Start by reading the [Quickstart](Quickstart) article if you're familiar with OpenComputers and non-OC GUI
libraries (Qt, GTK, etc.)—it shows how to build a simple GUI application. There's also the [Tutorial](Tutorial)
that goes over the concepts thoroughly. Finally, use the [API Reference](../) to find the documentation
for the library contents.

Have fun using the library!
