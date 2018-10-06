# Contributing

Great to see you interested in contributing – and reading the Contribution Guidelines. Having one is a reason to
celebrate – someone doing both is almost unheard of. :D

Compared to others Lua is a simple programming language and therefor easy to learn. This also makes it easy to
stumble over your own feet.

From my experiences I came up with a set of guidelines that keeps the code maintainable and as stable as possible.

**But don't let them hold you back from contributing.**

I am aware that not everyone in the EE Community is a professional coder and this totally fine.
Please contribute your code anyways and someone else can take over to either give you hints how to improve your
code or do the fixes themselves. Lua is really easy to get into and once you get familiar with some patterns they are
really easy to apply.

[![Build Status](https://travis-ci.org/czenker/lively-epsilon.svg?branch=master)](https://travis-ci.org/czenker/lively-epsilon)
[![Test Coverage](https://codecov.io/github/czenker/lively-epsilon/branch/master/graphs/badge.svg)](https://codecov.io/gh/czenker/lively-epsilon)

Thanks for reading. Now here are the Guidelines.


## Scope Variables

Using `local` should be the norm. Don't use global variables unless you have a real good reason.

Spamming the global scope with dozens of variables will inevitable lead to side effects, weired errors, wasted time and grey hair as the project grows.

Good:

```lua
function()
  local foo = 42
  local bar = calculateBar()
  return foo + bar
end
```

Bad:

```lua
function()
  foo = 42
  bar = calculateBar() -- nasty if calculateBar() changes the value of "foo"
  return foo + bar
end
```

## use logs at appropriate levels

Logging is a good thing. It can help recognize problems early and make debugging much simpler. If you use the correct log level it is simple to filter only for logs the user is interested in.

* `logError`: Something went wrong. This could lead to parts of the scenario (or even the whole) malfunctioning.
* `logWarn`: A potentially harmful situation, that might lead to an error in the future
* `logInfo`: Information on the progress or state of the application at a coarse-grained level.
* `logDebug`: Information on the internal state of the application that might be helpful to figure out bugs in the library.

Good:

```lua
logError("first parameter should be a Station, but got string")
logWarning("List of upgrades is empty. This is probably not intended.")
logInfo("The mission ended because the player ship was destroyed")
logDebug("Players are 20u from their target")
```
Logged messages should always be in english.

## All species welcome

This goes in two ways.

First, Lively Epsilon should not impose any back story on the universe. It should contain concepts that are independent of specific factions, races or spoken languages. Don't assume the universe knows some "Human Race" let alone a language called "English".

So, secondly, do not hard-code labels or any messages the player might see. All those texts have to be changeable by the coder.

Good:

```lua
function button(label)
  return player:addCustomInfo("helms", "button", label)
end
```

Bad:

```lua
player:addCustomInfo("helms", "button", "Click me")
```

## Check input as early as possible

We are dealing with human coders who tend to do mistakes – and you should point them out as early as possible.

Lua, as a weakly-typed language, has the tendency to fail late which can lead to frustration if it happens in the middle of a mission. By checking inputs we can reduce that frustration a little.

Good:

```lua
function foo(bar)
  if not isNumber(bar) then error("bar should be a number") end
  return bar + 21
end

foo(21) -- = 42
foo("21") -- error! Would be "2121" otherwise
```

Bad:

```lua
local myMissions = {}

function setMissions(missions)
  myMissions = missions
end

function getFirstMission()
  return missions[1]
end

setMissions(42)
-- lot of stuff happening here
getFirstMission() -- error!
```

## Use functions for public API

Or more precisely: Don't use properties as public API! The reason is that using functions – even if a property would be enough – allows to later change the implementation without breaking the public API. And there is no way to prevent write access to a property that should only be readable.

Good:

```lua
local bar = 42

Foo = {
  getBar = function()
    return bar
  end
}
```

Bad:

```lua
Foo = {
  bar = 42
}
```

## Write tests

These tests should be examples on how a coder would use that functionality and what output to expect. It should describe all the intentional behavior of that piece of code (aka "Behavior Tests"). An intentional behavior could also be that error occurs on some input.

If useful you can also write tests on a function level (aka "Unit Tests") or a set of associated pieces of code (aka "Component Test"). Writing tests that heavily relies on Empty Epsilon is harder, but possible within limitations if you mock parts of the game engine.

The goal of those tests is that new functionality can be added or existing code can be changed without breaking already existing features. This is why it is also useful to write a test once you found a bug to make sure that this bug will never occur anymore.

Good:

* test that a person generator returns Person objects...
* ...and does not use the same name twice
* test that a function fails if something other than a CpuShip is given
* test that a configurable callback is triggered

Bad:

* test that an info message is logged
* test that a function works with all numbers between 1 and 4200
