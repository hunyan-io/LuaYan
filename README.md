# LuaYan
## About
LuaYan is an easy-to-use system that replaces the load/loadstring function in controled environments where such functionalities are limited or blocked, written in vanilla lua.<br/>
It allows the user to easily add or modify operators and also introduces new assignment operators.
## How to use
All you need to do is to require the module.<br/>
```lua
local loader = require("luayan")
```
And use one of the functions `loader.readScript`, `loader.readLine`, `loader.readExpression`, `loader.removeComments`.
## Functions
### readScript ( script, environment )
Loads a given string in a given environment.<br/><br/>
**Example:**
```lua
local loader = require("luayan")

loader.readScript( [[
  local str = "Hello"
  print(str..", World!") --Hello, Word!
]], _G)
```
### readLine ( script, environment )
Loads the first line or block of code in an environment.<br/>
Returns the remaining script.
> This function doesn't remove comments before reading.
**Example:**
```lua
local loader = require("luayan")

local script = loader.readLine( [[
  print( ({ a = 0,
            b = 1 }).a )
  print("Hello, Word!")
]], _G) --prints 0.
print(script) --prints [[print("Hello, World!")]]
```
### readExpression ( script, environment, unary )
Evaluates an expression in an environment.
Returns the remaining script after the expression, the expression value(s)
If unary is true, it will stop before the first operator (unless it's the ^ operator)
**Example:**
```lua
local loader = require("luayan")

print( loader.readExpression( [[1 + 8 / 2 example]], {}, false ) )
--prints " example", 5
print( loader.readExpression( [[1 + 8 / 2 unary example]], {}, true ) )
--prints " + 8 / 2 unary example", 1
```
### removeComments ( script )
Removes all the comments in a script.
Returns the script without comments.
**Example:**
```lua
local loader = require("luayan")

print( loader.removeComments [=[ local a = "example -- string" -- [[ some
comment 
here ]] ]=] )
--prints [[ local a = "example -- string"  ]]
```
