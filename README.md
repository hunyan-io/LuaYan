# LuaYan
## About
LuaYan is an easy-to-use system that replaces the Lua load/loadstring function in controlled environments where such functionalities are limited or blocked, written in pure Lua.<br/>
It also allows the user to easily add or modify operators and introduces new assignment operators.
## How to use
All you need to do is to require the module.<br/>
```lua
local loader = require("luayan")
```
And use one of the functions `loader.readScript`, `loader.readLine`, `loader.readExpression`, `loader.removeComments`.
## Functions
### readScript ( script, environment )
Loads a given string in a given environment.<br/>
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
Returns the remaining script.<br/>
> This function doesn't remove comments before reading.<br/>
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
Evaluates an expression in an environment.<br/>
Returns the remaining script after the expression, the expression value(s)<br/>
If unary is true, it will stop before the first operator (unless it's the ^ operator)<br/>
> This function doesn't remove comments before reading.<br/>
**Example:**
```lua
local loader = require("luayan")

print( loader.readExpression( [[1 + 8 / 2 example]], {}, false ) )
--prints " example", 5
print( loader.readExpression( [[1 + 8 / 2 unary example]], {}, true ) )
--prints " + 8 / 2 unary example", 1
```
### removeComments ( script )
Removes all the comments in a script.<br/>
Returns the script without comments.<br/>
**Example:**
```lua
local loader = require("luayan")

print( loader.removeComments [=[ local a = "example -- string" -- [[ some
comment 
here ]] ]=] )
--prints [[ local a = "example -- string"  ]]
```
## Operators
The loader makes it easy to add and modify operators functions.<br/>
Since it was written in lua 5.1, the normal version only adds the floor division operator "//"<br/>
The bitwise edition adds all bitwise operators but requires a bit library.<br/>
If you are using lua 5.3, it is easy to modify the bitwise edition and use the bitwise operators instead of the bit library.<br/>
You can add other operators by editing the `operators` table in the source code, as well as editing the `orderPatterns` and `fastPatterns` that are used to match these operators. It is also possible to add unary operators.
## Assignment Operators
Another thing that this loader adds is the assignment operators which are:<br/>
`+=, -=, *=, /=, //=, %=, ^=, ..=, and=, or=`<br/>
The bitwise edition also adds bitwise assignment operators such as `>>=, |=, ~=`
**Example:**
```lua
local loader = require("luayan")
loader.readScript([=[
  local a = -2
  a += 5
  print(a) --3
]=], _G)
```
