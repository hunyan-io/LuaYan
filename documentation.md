## Functions
### readScript ( script, environment, removeComments )
Loads a given string in a given environment.<br/>
`removeComments` determines whether or not to remove comments before reading. (Default is **true**)<br/><br/>
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
Returns the remaining script.<br/><br/>
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
Returns the remaining script after the expression and the expression value(s)<br/>
If unary is true, it will stop before the first operator (unless it's the '^' operator)<br/><br/>
**Example:**
```lua
local loader = require("luayan")

print( loader.readExpression( [[1 + 8 / 2 example]], {}, false ) )
--prints " example", 5

print( loader.readExpression( [[1 + 8 / 2 unary example]], {}, true ) )
--prints " + 8 / 2 unary example", 1
```
### removeComments ( script, keepLines )
Removes all the comments in a script.<br/>
`keepLines` determines whether or not to keep the same amount of lines of multi-line comments. (Default is **false**)<br/>
Returns the script without comments.<br/><br/>
**Example:**
```lua
local loader = require("luayan")

print( loader.removeComments [=[ local a = "example -- string" -- [[ some
comment 
here ]] ]=] )
--prints [[ local a = "example -- string"  ]]
```
