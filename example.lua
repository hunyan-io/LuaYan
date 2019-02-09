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

print(test) --> nil

script = loader.readLine(script, _G) --reads function and return the remaining script

print(test) --> function

loader.readLine(script, _G) --> a test b c