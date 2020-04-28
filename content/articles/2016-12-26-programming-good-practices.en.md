---
title: "Programming good practices"
date: 2016-12-26
---
Inspired by the golang language, especially its interfaces that allows decoupling without introducing dependencies.

First, some guidelines that shows the direction to take but with no hard rules:

- Separate private imports from public imports. Private imports are only needed for the implementation. Public imports are exposed to other modules and are visible to them because their types appear in public function signatures or public types.

- In public module interface, avoid using types from other modules that are not completely abstracted as an interface type. Do not use pointer to struct defined elsewhere in your public function arguments. Except probably from platform types (`*net.URL` or `*context.Context` probably applies).

- Use basic types with no object characteristics, no defined methods, in public module interfaces. Better to rely on value to be a good exchange format than on complex objects that return objects and objects. This simplifies code and ensures that there is no side effects. Data layout is protocol.

- Extract side effect generating code from logic modules (most of the code) to put this in dedicated modules that implements an interface. Composition between logic modules and side effect generating modules should happen at top level only.

Some metrics (lower is better):

- median module code size (not average)
- maximum module code size
- absolute number of public imports (imports used in public interfaces). An imported module is only counted once for the entire codebase
- absolute number of public imported types that are not interfaces (a public type is counted once per module of the application)

These should not be at zero. Just measure when they augment. Either you have a good reason and can explain it, or it should't happen. Increase can be interpreted as increase of the common/runtime interface.

See also the [boundaries task by destroy all software](https://www.destroyallsoftware.com/talks/boundaries)

