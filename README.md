# Löve Starter Template

## Should you use this template?

It depends. If you're just starting out with Lua and or Love2D, you might learn better by toying around without relying on libraries or starter projects like this one. However if you're a more experienced developer, you might enjoy the fact that a lot of boilerplate code has been handled for you. As such, you may want to use this starter project and or reuse some parts of it in order to build your own starter project.

You must keep in mind that this project doesn't have the pretention to be "the best" or "the only way" to create or handle a Love2D project. It's simply the way I like to do things when creating my projects.

## What's included

* [Bump](https://github.com/kikito/bump.lua): A collision-detection library for axis-aligned rectangles.
* [Classic](https://github.com/rxi/classic): A tiny class module for Lua (globally imported as Object when requiring shep).
* [Lume](https://github.com/rxi/lume): A collection of functions geared towards game development. Also provides module hotswapping.
* [Hump.timer](https://github.com/vrld/hump/blob/master/timer.lua): A simple interface to schedule the execution of functions.
* [Shep](https://github.com/Shepardeon/love2d-starter-template/tree/main/lib/shep): A starter library which brings an opiniated game structure which can handle input, game states, scene, entities, cameras and more.
* A VSCode configuration based on [Sheepolution's book](https://sheepolution.com/learn/book/bonus/vscode).
* A build task wrapping [makelove](https://github.com/pfirsich/makelove) which needs to be installed separately.
* An opinionated directory structure.

## Shep Features

* A Game > Scene > Entity hierarchy
* An event system to register and subscribe to events (observer pattern)
* An input manager system which handles keyboard, mouse, gamepad (button press, release, hold, sequence)
* A delegate state machine which represents states and stateflows using regular functions
* An atlas management system that can use spritebatch
* An animation system which uses the atlas system
* A camera system that can handle multiple layers with parallax
* A sahder pipeline that can chain multiple shaders back to back
* A rendering pipeline that combines camera+shaders+resolution handling
* A debug graph which can be used to monitor update time, draw time, memory usage and so on...
* An async loading system which allows to load game resources (images, fonts, sounds and more) without blocking the main thread
* Utility functions to operate on coordinates, vector components and tables

## Planned features

As of now, the library is about ~70-80% done before I'm contempt with it for a 1.0.0 release. On top of revisiting some existing modules to fix issues or add new features (ie. add memory details and graphics stats to the debug graph, state machines not able to be used with "self") I have the following features planned:

* An audio manager to put sounds in audio "categories" and manage their volume
* A (simple) UI Library which can handle layout, buttons, label and 9Patch
* A localization module
* A loader for [Ldtk](https://ldtk.io/)

## License

All included libraries in `lib/` remain under their original license. Except for Shep and all original code which is distributed under the MIT License (see [LICENSE](https://github.com/Shepardeon/love2d-starter-template/blob/main/LICENSE))

Included asset (ranger_f.png) is shared under CC BY 3.0, original author is [Antifarea](https://opengameart.org/content/antifareas-rpg-sprite-set-1-enlarged-w-transparent-background-fixed)
