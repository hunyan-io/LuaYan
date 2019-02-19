# LuaYan
## About
LuaYan is an easy-to-use system that replaces the Lua load/loadstring function in controlled environments where such functionalities are limited or blocked, written in pure Lua.<br/>
It also allows the user to easily add or modify operators and introduces new assignment operators.
## How to use
No dependencies are needed.<br/>
Just require the module.<br/>
```lua
local loader = require("luayan")
```
And use one of the functions `loader.readScript`, `loader.readLine`, `loader.readExpression`, `loader.removeComments`.
## Features
### Operators
The loader makes it easy to add and modify operators functions.<br/>
Since it was written in lua 5.1, the normal version only adds the floor division operator "//"<br/>
The bitwise edition adds all bitwise operators but requires a bit library.<br/>
If you are using lua 5.3, it is easy to modify the bitwise edition and use the bitwise operators instead of the bit library.<br/>
You can add other operators by editing the `operators` table in the source code, as well as editing the `orderPatterns` and `fastPatterns` that are used to match these operators. It is also possible to add unary operators.
### Assignment Operators
Another thing that this loader adds is the assignment operators which are:<br/>
`+=, -=, *=, /=, //=, %=, ^=, ..=, and=, or=`<br/>
The bitwise edition also adds bitwise assignment operators such as `>>=, |=, ~=`
## Example
```lua
local loader = require("luayan")

local env = setmetatable({},{__index=_G})

local script = [==[
	function test(arg1, arg2, ...)
	    local arg2 = arg2 or "test"
	    local all_arguments = arg1
	    for index, value in next, ({arg2, ...}) do
	        all_arguments = all_arguments .. " " .. value
	    end
	    print(all_arguments)
	end
	test("a", nil, "b", "c")
]==]

loader.readScript(script, env) --> a test b c
```
