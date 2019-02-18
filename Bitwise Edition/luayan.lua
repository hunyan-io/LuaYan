--[=[

LuaYan loader v0.2 bitwise edition

The loader was written in lua 5.1 and was also tested in lua 5.3

This edition is supposed to add bitwise operators:
& bitwise and
| bitwise or
~ bitwise xor
~ (unary) bitwise not
>> bitwise right shift
<< bitwise left shift

it also adds the floor division operator "//"

as well as assignment operators such as "+=", "-=", ">>=", "<<=", "&=", "|="...

**IMPORTANT: PLEASE READ
Since this was originally written in lua 5.1,
you will have to require a bitwise library
If you are using lua 5.3 (which support bitwise operators), or using any other libs
you can easily edit the operators functions below in the [[OPERATORS]] part.
]=]

local matchstr, sub, gsub, gmatch, char, repstr = string.match, string.sub, string.gsub, string.gmatch, string.char, string.rep
local max = math.max
local unpack = table.unpack

--[['#' OPERATOR / UNPACK FIX]]--
local function len(tab)
    local i = 0
    for k in next, tab do
        i = type(k) == "number" and k or i
    end
    return i
end
do
	local upk = unpack
	unpack = function(tab, i, j)
		return upk(tab, i, j or len(tab))
	end
end

--[[MANAGING ENVIRONMENTS]]--
local globals
local function getDefinedObject(env)
	local defined = {}
	for i in next, env do
		defined[i] = true
	end
	for i in next, env["*nil"] do
		defined[i] = true
	end
	return defined
end
local function newChildEnv(env, defined)
	return setmetatable(
		{
			["*parentDefined"] = env~=globals and setmetatable(defined or getDefinedObject(env), {__index=env["*parentDefined"]}) or {},
			["*nil"] = {},
			["*parent"] = env
		}, 
		{ 
			__index = function(tab,index) 
				if not rawget(tab,"*nil")[index] then 
					if rawget(tab,"*parentDefined")[index] then
						return env[index]
					else
						return globals[index]
					end
				end
			end,
			__newindex = function(tab,key,value)
				rawset(tab,key,value)
				if value == nil then
					tab["*nil"][key] = true
				else
					tab["*nil"][key] = nil
				end
			end
		}
	)
end
local function setDeclaredVariable(tab,index,value,scope)
	if tab == scope then
		while tab ~= globals do
			if rawget(tab, index) ~= nil or tab["*nil"][index] then
				if value == nil then
					tab["*nil"][index] = true
				end
				break
			else
				tab = tab["*parent"]
			end
		end
	end
	tab[index] = value
end
local returnObject, breakObject = {}, {}




--[[OPERATORS]]--
local evaluate
local operators = {
	["or"] = function(a,b,...) return evaluate(a,...) or evaluate(b,...) end,
	["and"] = function(a,b,...) return evaluate(a,...) and evaluate(b,...) end,
	["<"] = function(a,b,...) return evaluate(a,...) < evaluate(b,...) end,
	[">"] = function(a,b,...) return evaluate(a,...) > evaluate(b,...) end,
	["<="] = function(a,b,...) return evaluate(a,...) <= evaluate(b,...) end,
	[">="] = function(a,b,...) return evaluate(a,...) >= evaluate(b,...) end,
	["~="] = function(a,b,...) return evaluate(a,...) ~= evaluate(b,...) end,
	["=="] = function(a,b,...) return evaluate(a,...) == evaluate(b,...) end,
	["|"] = function(a,b,...) return bit.bor(evaluate(a,...),evaluate(b,...)) end,
	["~"] = function(a,b,...) return bit.bxor(evaluate(a,...),evaluate(b,...)) end,
	["&"] = function(a,b,...) return bit.band(evaluate(a,...),evaluate(b,...)) end,
	["<<"] = function(a,b,...) return bit.lshift(evaluate(a,...),evaluate(b,...)) end,
	[">>"] = function(a,b,...) return bit.rshift(evaluate(a,...),evaluate(b,...)) end,
	[".."] = function(a,b,...) return evaluate(a,...) .. evaluate(b,...) end,
	["+"] = function(a,b,...) return evaluate(a,...) + evaluate(b,...) end,
	["-"] = function(a,b,...) return evaluate(a,...) - evaluate(b,...) end,
	["*"] = function(a,b,...) return evaluate(a,...) * evaluate(b,...) end,
	["/"] = function(a,b,...) return evaluate(a,...) / evaluate(b,...) end,
	["//"] = function(a,b,...) return math.floor(evaluate(a,...)/evaluate(b,...)) end,
	["%"] = function(a,b,...) return evaluate(a,...) % evaluate(b,...) end,
	["^"] = function(a,b,...) return evaluate(a,...) ^ evaluate(b,...) end
}
local orderPatterns = {
	"(.*%d)(or)(%d.*)",
	"(.*%d)(and)(%d.*)",
	"(.*%d)([<>~=]=?)(%d.*)",
	"(.*%d)(|)(%d.*)",
	"(.*%d)(~)(%d.*)",
	"(.*%d)(&)(%d.*)",
	"(.*%d)([<>][<>])(%d.*)",
	"(.*%d)(%.%.)(%d.*)",
	"(.*%d)([%+%-])(%d.*)",
	"(.*%d)([%*/%%]/?)(%d.*)",
	"(.*%d)(%^)(%d.*)"
}
local fastPatterns = {"^%s*([%+%-%*/%%%^=~><%.|&][=<>/%.]?)()","^%s*(and)()[^_%w]","^%s*(or)()[^_%w]"}
local unaryOperators = {
	["#"] = function(a) return #a end,
	["-"] = function(a) return -a end,
	["not"] = function(a) return not a end,
	["~"] = function(a) return bit.bnot(a) end
}
local unaryPattern = "[#%-~]"
local opPrecedingUnaries = {"%^"} --List of operators that has superior precedence than unary operators.
local assignOperators = {
	["="] = function(scope,var,value) return value end,
	["+="] = function(scope,var,value) return scope[var]+value end,
	["-="] = function(scope,var,value) return scope[var]-value end,
	["*="] = function(scope,var,value) return scope[var]*value end,
	["/="] = function(scope,var,value) return scope[var]/value end,
	[">>="] = function(scope,var,value) return bit.rshift(scope[var],value) end,
	["<<="] = function(scope,var,value) return bit.lshift(scope[var],value) end,
	["^="] = function(scope,var,value) return scope[var]^value end,
	["%="] = function(scope,var,value) return scope[var]%value end,
	["..="] = function(scope,var,value) return scope[var]..value end,
	["or="] = function(scope,var,value) return scope[var] or value end,
	["and="] = function(scope,var,value) return scope[var] and value end,
	["//="] = function(scope,var,value) return math.floor(scope[var]/value) end,
	["|="] = function(scope,var,value) return bit.bor(scope[var],value) end,
	["&="] = function(scope,var,value) return bit.band(scope[var],value) end,
	["~="] = function(scope,var,value) return bit.bxor(scope[var],value) end
}




--[[USEFUL FUNCTIONS]]--
local fullScriptLen, currentPosition, currentScript
local function unescapeString(str)
	str = gsub(str,"\\(.)(%d?%d?)",function(a, b)
        if a == "a" then return "\a"..b
        elseif a == "b" then return "\b"..b
        elseif a == "f" then return "\f"..b
        elseif a == "n" then return "\n"..b
        elseif a == "r" then return "\r"..b
        elseif a == "t" then return "\t"..b
        elseif a == "v" then return "\v"..b
        elseif a == "\\" then return "\\"..b
        elseif a == "\"" then return "\""..b
        elseif a == "'" then return "'"..b
        elseif a == "[" then return "["..b
        elseif a == "]" then return "]"..b
        elseif matchstr(a,"^%d$") then return char(tonumber(a..b))
        else error("invalid escape sequence") end
    end)
    return str
end
local function unfinishedStrings(script)
	while true do
		local m = matchstr(script,"^[^\"']-%[(=-)%[") or matchstr(script,"^[^']-(\")") or matchstr(script,"'")
		if m then
			local suc
			if m ~= '"' and m ~= "'" then
				suc = matchstr(script,"%["..m.."%[.-%]"..m.."%]()")
			else
				local s; s, suc = matchstr(script,m.."(.-)"..m.."()")
				if suc then
					local c = 0
					repeat
						s = unescapeString(s.."0")
						if sub(s,-1) == char(0) then
							c = c + 1
							s, suc = matchstr(script,m..'(.-'..repstr(m..'.-',c)..')'..m..'()')
						else
							break
						end
					until false	
				end
			end
			if suc then
				script = sub(script,suc)
			else
				return m
			end
		else
			return false
		end
	end
end
local function keepLines(a)
	return a:gsub("[^\n]+", "")
end
local function removeComments(script, keep)
	local n = 1
	while true do
		local scr = sub(script,n)
		local z, block = matchstr(scr,"()%-%-(%[?=*%[?)")
		if z then
			local m = unfinishedStrings(sub(scr,1,z-1))
			if not m then
				local b = matchstr(block,"%[(=-)%[") 
				if b then
					script = sub(script,1,n-1)..gsub(scr,"%-%-%["..b.."%[.-%]"..b.."%]", keep and keepLines or "", 1)
				else
					script = sub(script,1,n-1)..gsub(scr,"%-%-.-\r?\n", "\n", 1)
				end
			else
				local is, d, s = sub(scr,z)
				if m == "'" or m == '"' then
					s, d = matchstr(is,"(.-)"..m.."()")
					local c = 0
					repeat
						s = unescapeString(s.."0")
						if sub(s,-1) == char(0) then
							c = c + 1
							s, d = matchstr(is,'(.-'..repstr(m..'.-',c)..')'..m..'()')
						else
							break
						end
					until false	
				else
					d = matchstr(is,"%]"..m.."%]()")
				end
				n = n + z + d - 2
			end
		else
			break
		end
	end
	return script
end
local function returnTable(iter, ...)
	return function(...)
		local a = {iter(...)}
		if a[1] then
			return a[1], a
		end
	end, ...
end
local function matchWord(script)
	local word, n = matchstr(script,"^%s*([_%a][_%w]*)()")
	if word then
		script = sub(script,n)
	end
	return script, word
end
local function checkReturn(ret, scopeType, scr, ln)
	if ret[1] == returnObject then
		if scopeType == "function" then
			fullScriptLen, currentPosition = scr, ln
			return unpack(ret,2)
		elseif scopeType == "main" then
			error("'return' used outside function")
		else
			fullScriptLen, currentPosition = scr, ln
			return unpack(ret)
		end
	end
	if ret[1] == breakObject then
		if scopeType == "function" or scopeType == "main" then
			error("'break' used outside loop")
		else
			fullScriptLen, currentPosition = scr, ln
			return breakObject
		end
	end
end



--[[MAIN FUNCTIONS]]
local readExpression, readScript
local function readTable(tblstr, scope)
	local c = 0
	local a = tblstr:match("^%s*{value%[1%]%(unpack%(args,1,c%)%)")
	local n, brk, e, _ = matchstr(tblstr,"^%s*{()%s*(}?)()")
	local value = {}
	while brk == "" do
		if _ == "" then
			error("error")
		end
		tblstr = sub(tblstr,n)
		n = matchstr(tblstr,"^%s*%[()")
		local index, val
		if n then
			tblstr, index = readExpression(sub(tblstr,n),scope)
			n = matchstr(tblstr,"^%s*%]%s*=%s*()")
		else
			index, n = matchstr(tblstr,"^%s*([_%a][_%w]*)%s*=%s*()")
			if not n then
				c = c + 1
				index = c
				n = 1
			end
		end
		local match = {readExpression(sub(tblstr,n),scope)}
		tblstr = match[1]
		if scope then
			value[index] = match[2]
			local k = c
			if n == 1 then
				for i = 3, len(match) do
					k = k + 1
					value[k] = match[i]
				end
			end
			for i = k+1, len(value) do
				value[i] = nil
			end
		end
		_, n, brk, e = matchstr(tblstr,"^%s*(,?)()%s*(}?)()")
	end
	return sub(tblstr,e), value
end
local function matchScopeBody(script, addLen)
	local len = readScript(script,nil,"",nil,true)
	local body = sub(script,1,len)
	script = sub(script,len+(addLen or 3)+1)
	return script, body
end
function evaluate(value, scope, vars, inevaluated, counter)
	local n 
	for i = 1, #orderPatterns do
		value, n = gsub(value,orderPatterns[i], function(a,op,b) counter = counter + 1 vars[counter] = operators[op](a,b,scope,vars,inevaluated,counter) return tostring(counter) end)
		if n ~= 0 then
			break
		end
	end
	local i = tonumber(matchstr(value,"%d+"))
	if inevaluated[i] then
		vars[i] = select(2,readExpression(inevaluated[i], scope,nil,nil,true))
		inevaluated[i] = nil
	end
	return vars[i]
end
function readExpression(script, scope, isUnary, processCall, skipCurrent)
	if not skipCurrent then
		currentScript = script
	end
	local value, mustCall, callIsLast, isIndexable
	if processCall then
		value = processCall
		isIndexable = true
	else
		value = {}
		local word; script, word = matchWord(script)
		if word then
			if word == "function" then
				local varNames, n, body = matchstr(script,"^%s*%((.-)%)()")
				if not varNames then
					error("error")
				end
				local initialScript = sub(script,n)
				script, body = matchScopeBody(initialScript)
				if scope then
					local defined = getDefinedObject(scope)
					local ln = currentPosition+fullScriptLen-#initialScript
					value[1] = function(...)
						local env = newChildEnv(scope,defined)
						local params, c, isLast = {...}, 0, false
						for arg in gmatch(varNames,"%s*([^,]+)%s*") do
							if isLast then
								error("error")
							end
							c = c + 1
							if arg == "..." then
								env["..."] = {unpack(params,c,select("#",...))}
								isLast = true
							else
								env[arg] = params[c]
							end
						end
						return readScript(body, env, "function", ln)
					end
				end
			elseif unaryOperators[word] then
				script, value[1] = readExpression(script, scope, true)
				if scope then
					value[1] = unaryOperators[word](value[1])
				end
			elseif word == "true" then
				value[1] = true
			elseif word == "false" then
				value[1] = false
			elseif word == "nil" then
				value[1] = nil
			else
				if scope then
					value[1] = scope[word]
				end
				isIndexable = true
			end
		else
			local n; value[1], n = matchstr(script,"^%s*\"(.-)\"()")
			if n then
				local c = 0
				repeat
					value[1] = unescapeString(value[1].."0")
					if sub(value[1],-1) == char(0) then
						c = c + 1
						value[1], n = matchstr(script,'^%s*"(.-'..repstr('".-',c)..')"()')
					else
						break
					end
				until false	
				value[1] = sub(value[1],1,-2)
				script = sub(script,n)
			else
				value[1], n = matchstr(script,"^%s*'(.-)'()")
				if n then
					local c = 0
					repeat
						value[1] = unescapeString(value[1].."0")
						if sub(value[1],-1) == char(0) then
							c = c + 1
							value[1], n = matchstr(script,'^%s*\'(.-'..repstr('\'.-',c)..')\'()')
						else
							break
						end
					until false		
					value[1] = sub(value[1],1,-2)
					script = sub(script,n)
				else
					local pat; pat, value[1], n = matchstr(script,'^%s*%[(=-)%[(.-)%]%1%]()')
					if n then
						value[1], n = matchstr(script,'^%s*%['..pat..'%[(.-)%]'..pat..'%]()')
						script = sub(script,n)
					else
						local p, z, n = matchstr(script,"^%s*(%.?)(%d+)()")
						if z then
							script = sub(script,n)
							if p == "" then
								local d, n = matchstr(script,"^%s*%.(%d+)()")
								if d then
									script = sub(script,n)
									z = z .. "." .. d
								else
									d, n = matchstr(script,"^%s*x(%w+)()")
									if d then
										if z ~= "0" then
											error("error")
										end
										script = sub(script,n)
										z = z .. "x" .. d
									end
								end
								value[1] = tonumber(z)
							else
								value[1] = tonumber("0."..z)
							end
						else
							n = matchstr(script,"^%s*%(()")
							if n then
								script, value[1] = readExpression(sub(script,n),scope)
								n = matchstr(script,"^%s*%)()")
								script = sub(script,n)
								isIndexable = true
							elseif matchstr(script,"^%s*{") then
								script, value[1] = readTable(script, scope)
							else
								n = matchstr(script,"^%s*%.%.%.()")
								if n then
									script = sub(script,n)
									if scope then
										if not scope["..."] then
											error("error")
										end
										value = scope["..."]
									end
								else
									local op, n = matchstr(script,"^%s*("..unaryPattern..")()") 
									if n then
										if not unaryOperators[op] then
											error("error")
										end
										script, value[1] = readExpression(sub(script,n),scope,true)
										if scope then
											value[1] = unaryOperators[op](value[1])
										end
									else
										error("unexpected character")
									end
								end
							end
						end
					end
				end
			end
		end
	end
	while isIndexable do
		callIsLast = true
		local arg, n
		if matchstr(script,"^%s*{") then
			script, arg = readTable(script, scope)
			if scope then
				if mustCall then
					value = { value[1](mustCall, arg) }
				else
					value = { value[1](arg) }
				end
			end
			mustCall = false
		else
			arg, n = matchstr(script,"^%s*\"(.-)\"()")
			if arg then
				local c = 0
				repeat
					arg = unescapeString(arg.."0")
					if sub(arg,-1) == char(0) then
						c = c + 1
						arg, n = matchstr(script,'^%s*"(.-'..repstr('".-',c)..')"()')
					else
						break
					end
				until false		
				arg = sub(arg,1,-2)
				script = sub(script,n)
				if scope then
					if mustCall then
						value = {value[1](mustCall, arg)}
					else
						value = {value[1](arg)}
					end
				end
				mustCall = false
			else
				arg, n = matchstr(script,"^%s*'(.-)'()")
				if arg then
					local c = 0
					repeat
						arg = unescapeString(arg.."0")
						if sub(arg,-1) == char(0) then
							c = c + 1
							arg, n = matchstr(script,'^%s*\'(.-'..repstr('\'.-',c)..')\'()')
						else
							break
						end
					until false		
					arg = sub(arg,1,-2)
					script = sub(script,n)
					if scope then
						if mustCall then
							value = {value[1](mustCall, arg)}
						else
							value = {value[1](arg)}
						end
					end
					mustCall = false
				else
					local pat; pat, arg, n = matchstr(script,'^%s*%[(=-)%[(.-)%]%1%]()')
					if arg then
						script = sub(script,n)
						if scope then
							if mustCall then
								value = {value[1](mustCall, arg)}
							else
								value = {value[1](arg)}
							end
						end
						mustCall = false
					elseif matchstr(script,"^%s*%(") then
						local n = matchstr(script,"^%s*%(%s*%)()")
						if n then
							script = sub(script,n)
							if scope then
								if mustCall then
									value = {value[1](mustCall)}
								else
									value = {value[1]()}
								end
							end
						else
							local args, k, c = {}, 0
							if mustCall then
								k = 1
								args[k] = mustCall
							end
							n = matchstr(script,"^%s*%(()")
							while n do
								local match = {readExpression(sub(script,n),scope)}
								script = match[1]
								k = k + 1
								c = k
								for i = 2, len(match) do
									c = k + i - 2
									args[c] = match[i]
								end
								n = matchstr(script,"^%s*,()")
							end
							if scope then
								value = {value[1](unpack(args,1,c))}
							end
							n = matchstr(script,"^%s*%)()")
							script = sub(script,n)
						end
						mustCall = false
					else
						if mustCall then
							error("error")
						end
						n = matchstr(script,"^%s*%[()")
						if n then
							local index; script, index = readExpression(sub(script,n),scope)
							n = matchstr(script,"^%s*%]()")
							script = sub(script,n)
							if scope then
								value[1] = value[1][index]
							end
							callIsLast = false
						else
							local name; name, n = matchstr(script,"^%s*%.%s*([_%a][_%w]*)()")
							if n then
								script = sub(script,n)
								if scope then
									value[1] = value[1][name]
								end
								callIsLast = false
							else
								name, n = matchstr(script,"^%s*:%s*([_%a][_%w]*)()")
								if n then
									script = sub(script,n)
									if scope then
										mustCall = value[1]
										value[1] = value[1][name]
									else
										mustCall = true
									end
									callIsLast = false
								else
									break
								end
							end
						end
					end
				end
			end
		end
	end
	if processCall then
		if not callIsLast then
			error("error")
		end
		return script
	end
	if not isUnary then
		local vars, c, loop, valProcess, inevaluated = {value[1]}, 1, true, "1", {}
		while loop do
			loop = false
			for i = 1, #fastPatterns do
				local op, n = matchstr(script,fastPatterns[i])
				if op then
					if not operators[op] then
						error("error")
					end
					loop = true
					local iscript, exp = sub(script,n)
					script = readExpression(iscript, nil, true)
					exp = sub(iscript,1,#iscript-#script)
					c = c + 1
					inevaluated[c] = exp
					if scope then
						valProcess = valProcess .. op .. c
					end
					break
				end
			end
		end
		if scope and valProcess ~= "1" then
			value = {evaluate(valProcess, scope, vars, inevaluated, c)}
		end
	else
		for i = 1, #opPrecedingUnaries do
			local op, n = matchstr(script,"^%s*("..opPrecedingUnaries[i]..")()")
			if n then
				local operant; script, operant = readExpression(sub(script,n),scope,true)
				if scope then
					value = {operators[op](value[1],operant)}
				end
				break
			end
		end
	end
	return script, unpack(value)
end
local function readLine(script, scope)
	currentScript = script
	local n = matchstr(script, "^%s*;()")
	if n then
		script = sub(script, n)
		if matchstr(script, "^%s*$") then
			return ""
		end
	end
	local word; script, word = matchWord(script)
	if word then
		if word == "local" then
			local varName; script, varName = matchWord(script)
			if varName then
				if varName == "function" then
					local fName, args, n, fBody = matchstr(script,"^%s*([_%a][_%w]*)%s*%((.-)%)()")
					local initialScript = sub(script,n)
					script, fBody = matchScopeBody(initialScript)
					if scope then
						local ln = currentPosition+fullScriptLen-#initialScript
						local defined = getDefinedObject(scope)
						scope[fName] = function(...)
							local env = newChildEnv(scope,defined)
							local params = {...}
							local c = 0
							local isLast = false
							for arg in gmatch(args,"%s*([^,]+)%s*") do
								if isLast then
									error("error")
								end
								c = c + 1
								if arg == "..." then
									env["..."] = {unpack(params,c,select('#',...))}
									isLast = true
								else
									env[arg] = params[c]
								end
							end
							return readScript(fBody, env, "function", ln)
						end
					end
				else
					local varNames = {}
					local c = 1
					varNames[c] = varName
					local n = matchstr(script,"^%s*,()")
					while n do
						c = c + 1
						script, varName = matchWord(sub(script,n))
						varNames[c] = varName
						n = matchstr(script,"^%s*,()")
					end
					local n = matchstr(script,"^%s*=()")
					c = 0
					local varValues, k = {}, 0
					while n do
						local match = {readExpression(sub(script,n),scope)}
						script = match[1]
						if scope then
							c = c + 1
							k = c
							for i = 2, len(match) do
								k = c + i - 2
								varValues[k] = match[i]
							end
						end
						n = matchstr(script,"^%s*,()")
					end
					if scope then
						for i = 1, #varNames do
							scope[varNames[i]] = i <= k and varValues[i] or nil
						end
					end
				end
			else
				error("error")
			end
		elseif word == "function" then
			local fName, args, n, fBody = matchstr(script,"^%s*([_%a][_%.:%s%w]*)%s*%(%s*(.-)%)()")
			local initialScript = sub(script,n)
			script, fBody = matchScopeBody(initialScript)
			if scope then
				local ln = currentPosition+fullScriptLen-#initialScript
				local tab = scope
				local last
				for n, l in gmatch(fName,"([^%.%s]+)%s*%.%s*([^%.%s]+)") do
					tab = tab[n]
					last = l
				end
				if not last then
					last = matchstr(fName,"[^:%s]+")
				end
				local method = matchstr(fName,"^%s*.-%s*:%s*(.*)%s*$")
				if method then
					tab = tab[last]
					last = method
				end
				local defined = getDefinedObject(scope)
				setDeclaredVariable(tab,last,function(...)
					local env = newChildEnv(scope,defined)
					if method then
						args = args == "" and "self" or "self,"..args
					end
					local params = {...}
					local c = 0
					local isLast = false
					for arg in gmatch(args,"%s*([^,]+)%s*") do
						if isLast then
							error("error")
						end
						c = c + 1
						if arg == "..." then
							env["..."] = {unpack(params,c,select('#',...))}
							isLast = true
						else
							env[arg] = params[c]
						end
					end
					return readScript(fBody, env, "function", ln)
				end, scope)
			end
		elseif word == "while" then
			local iscript = script
			script = readExpression(script, nil)
			local statement = sub(iscript,1,#iscript-#script)
			local n = matchstr(script,"^%s*do()")
			if n then
				local initialScript = sub(script,n)
				local body; script, body = matchScopeBody(initialScript)
				if scope then
					local ln = currentPosition+fullScriptLen-#initialScript
					while select(2,readExpression(statement, scope)) do
						local env = newChildEnv(scope)
						local ret = {readScript(body, env, "breakable", ln)}
						if ret[1] == returnObject then
							return unpack(ret)
						elseif ret[1] == breakObject then
							return script
						end
					end
				end
			else
				error("do expected")
			end
		elseif word == "for" then
			local varName, n = matchstr(script,"^%s*([_%a][_%w]*)%s*=()")
			if varName then
				local init; script, init = readExpression(sub(script,n), scope)
				n = matchstr(script,"^%s*,()")
				if n then
					local fin; script, fin = readExpression(sub(script,n), scope)
					local inc
					n = matchstr(script,"^%s*,()")
					if n then
						script, inc = readExpression(sub(script,n), scope)
						if scope and not inc then
							error("for step must be a number")
						end
					end
					n = matchstr(script,"^%s*do()")
					if n then
						local initialScript = sub(script,n)
						local body; script, body = matchScopeBody(initialScript)
						if scope then
							local ln = currentPosition+fullScriptLen-#initialScript
							for i = init, fin, inc or 1 do
								local env = newChildEnv(scope)
								env[varName] = i
								local ret = {readScript(body, env, "breakable", ln)}
								if ret[1] == returnObject then
									return unpack(ret)
								elseif ret[1] == breakObject then
									return script
								end
							end
						end
					else
						error("error")
					end
				else
					error("error")
				end
			else
				varName, n = matchstr(script,"^%s*(.-)%s+in%s+()")
				if not varName then
					error("error")
				end
				local args = {}
				local c, k = 0, 0
				while n do
					local match = {readExpression(sub(script,n), scope)}
					script = match[1]
					c = c + 1
					k = c
					for i = 2, len(match) do
						k = c + i - 2
						args[k] = match[i]
					end
					n = matchstr(script,"^%s*,()")
				end
				for i = k+1, len(args) do
					args[i] = nil
				end
				n = matchstr(script,"^%s*do()")
				if n then
					local initialScript = sub(script,n)
					local body; script, body = matchScopeBody(initialScript)
					if scope then
						local ln = currentPosition+fullScriptLen-#initialScript
						for _, vars in returnTable(args[1],args[2],args[3]) do
							local env = newChildEnv(scope)
							local c = 0
							for vname in gmatch(varName,"%s*([^,]+)%s*") do
								c = c + 1
								env[vname] = vars[c]
							end
							local ret = {readScript(body, env, "breakable", ln)}
							if ret[1] == returnObject then
								return unpack(ret)
							elseif ret[1] == breakObject then
								return script
							end
						end
					end
				else
					error("error")
				end
			end
		elseif word == "repeat" then
			local body, condition, initialScript
			local initialScript = script
			script, body = matchScopeBody(script, 5)
			condition = script
			script = readExpression(condition, nil)
			condition = sub(condition,1,#condition-#script)
			if scope then
				local ln = currentPosition+fullScriptLen-#initialScript
				repeat
					local env = newChildEnv(scope)
					local ret = {readScript(body, env, "breakable", ln)}
					if ret[1] == returnObject then
						return unpack(ret)
					elseif ret[1] == breakObject then
						return script
					end
				until select(2, readExpression(condition,scope))
			end
		elseif word == "if" then
			local condition; script, condition = readExpression(script, scope)
			local n = matchstr(script,"^%s*then()")
			local env
			if scope then
				env = newChildEnv(scope)
			end
			if n then
				local initialScript = sub(script,n)
				local body; script, body = matchScopeBody(initialScript, 0)
				if condition then
					if scope then
						local ln = currentPosition+fullScriptLen-#initialScript
						local ret = {readScript(body, env, "if", ln)}
						if ret[1] == returnObject or ret[1] == breakObject then
							return unpack(ret)
						end
					end
					local el, n = matchstr(script,"^else(i?f?)()")
					while n do
						if el == "if" then
							script = readExpression(sub(script,n),nil)
							n = matchstr(script, "^%s*then()")
						end
						script = matchScopeBody(sub(script,n),0)
						el, n = matchstr(script,"^else(i?f?)()")
					end
					script = sub(script,4)
				else
					n = matchstr(script,"^elseif()")
					while n do
						script, condition = readExpression(sub(script,n), scope)
						n = matchstr(script,"^%s*then()")
						if n then
							initialScript = sub(script,n)
							script, body = matchScopeBody(initialScript,0)
							if condition then
								if scope then
									local ln = currentPosition+fullScriptLen-#initialScript
									local ret = {readScript(body, env, "if", ln)}
									if ret[1] == returnObject or ret[1] == breakObject then
										return unpack(ret)
									end
								end
								local el, n = matchstr(script,"^else(i?f?)()")
								while n do
									if el == "if" then
										script = readExpression(sub(script,n),nil)
										n = matchstr(script, "^%s*then()")
									end
									script = matchScopeBody(sub(script,n),0)
									el, n = matchstr(script,"^else(i?f?)()")
								end
								script = sub(script,4)
								break
							end
						else
							error("error")
						end
						n = matchstr(script,"^elseif()")
					end
					if not condition then
						n = matchstr(script,"^else()")
						if n then
							initialScript = sub(script,n)
							script, body = matchScopeBody(sub(script,n))
							if scope then
								local ln = currentPosition+fullScriptLen-#initialScript
								local ret = {readScript(body, env, "if", ln)}
								if ret[1] == returnObject or ret[1] == breakObject then
									return unpack(ret)
								end
							end
						else
							script = sub(script,4)
						end
					end
				end
			else
				error("error")
			end
		elseif word == "elseif" then
			return "", #script+6
		elseif word == "else" then
			return "", #script+4
		elseif word == "end" then
			return "", #script+3
		elseif word == "do" then
			local initialScript = script
			local body; script, body = matchScopeBody(script)
			if scope then
				local ln = currentPosition+fullScriptLen-#initialScript
				local env = newChildEnv(scope)
				local ret = {readScript(body, env, "breakable", ln)}
				if ret[1] == returnObject then
					return unpack(ret)
				elseif ret[1] == breakObject then
					return script
				end
			end
		elseif word == "break" then
			if scope then
				return breakObject
			end
		elseif word == "return" then
			local n, c, k = 1, 0, 0
			local res = {}
			local word = select(2,matchWord(script))
			if matchstr(script,"^%s*$") or (word and (word=="end" or word=="elseif" or word=="else" or word=="until")) then
				if scope then
					return returnObject
				end
			else
				while n do
					local match = {readExpression(sub(script,n),scope)}
					script = match[1]
					c = c + 1
					k = c
					for i = 2, len(match) do
						k = c + i - 2
						res[k] = match[i]
					end
					n = matchstr(script,"^%s*,()")
				end
				if scope then
					return returnObject, unpack(res,1,k)
				end
			end
		elseif word == "until" then
			return "", #script+5
		else
			local varNames = {}
			local c = 0
			local vname = word
			local n = 1
			while n do
				script = sub(script,n)
				c = c + 1
				varNames[c] = {scope,vname}
				while true do
					n = matchstr(script,"^%s*%[()[^=%]]")
					if n then
						if scope then
							varNames[c][1] = varNames[c][1][varNames[c][2]]
						end
						script, varNames[c][2] = readExpression(sub(script,n),scope)
						n = matchstr(script,"^%s*%]()")
					else
						local name; name, n = matchstr(script,"^%s*%.([_%a][_%w]*)()")
						if n then
							if scope then
								varNames[c][1] = varNames[c][1][varNames[c][2]]
							end
							varNames[c][2] = name
						else
							break
						end
					end
					script = sub(script,n)
				end
				vname, n = matchstr(script,"^%s*,%s*([_%a][_%w]*)()")
			end
			if matchstr(script,"^%s*[:%(\"'{%[]") then
				local processCall = {}
				if scope then
					if #varNames > 1 then
						error("error")
					end
					processCall[1] = varNames[1][1][varNames[1][2]]
				end
				script = readExpression(script, scope, nil, processCall)
			else
				local op, n = matchstr(script,"^%s*(%S-=)%s*()")
				c = 0
				local varValues, k = {}, 0
				while n do
					local match = {readExpression(sub(script,n),scope)}
					script = match[1]
					if scope then
						c = c + 1
						k = c
						for i = 2, len(match) do
							k = c + i - 2
							varValues[k] = match[i]
						end
					end
					n = matchstr(script,"^%s*,()")
				end
				if scope then
					for i = 1, #varNames do
						setDeclaredVariable(varNames[i][1],varNames[i][2],assignOperators[op](varNames[i][1],varNames[i][2],i<=k and varValues[i] or nil),scope)
					end
				end
			end
		end
	else
		n = matchstr(script,"^%s*%(()")
		if n then
			local processCall = {}
			script, processCall[1] = readExpression(sub(script,n),scope)
			n = matchstr(script,"^%s*%)()")
			script = readExpression(sub(script,n), scope, nil, processCall)
		else
			error("unexpected character.")
		end
	end
	return script
end
function readScript(script, scope, scopeType, lines, returnLen)
	local a, b = fullScriptLen, currentPosition
	fullScriptLen, currentPosition = #script, lines or currentPosition
	local sLen = fullScriptLen
	local match = {}
	while not matchstr(script,"^%s*$") do
		match = {readLine(script, scope)}
		script = match[1]
		if script == breakObject or script == returnObject then
			return checkReturn(match, scopeType, a, b)
		end
	end
	fullScriptLen, currentPosition = a, b
	if returnLen then
		return sLen - (match[2] or sLen)
	else
		return unpack(match,2)
	end
end
local function handleError(func, script, scope, remComments, ...)
	globals = scope or _G
	globals._G = globals
	if remComments then
		script = removeComments(script, true)
	end
	scope = newChildEnv(globals, {})
	fullScriptLen, currentPosition = #script, 0
	local result = {pcall(func, script, scope, ...)}
	if result[1] then
		return unpack(result, 2)
	else
		error(result[2])
		currentPosition = currentPosition + fullScriptLen - #currentScript
		local line = select(2, gsub(sub(script,1,currentPosition), "\n", "")) + 1
		error("[LuaYan]:"..line..":"..matchstr(result[2] or "0:","%d+:(.*)$"))
	end
end


return {
	readExpression = function(script, env, unary, remComments)
						return handleError(readExpression, script, env, remComments, unary)
					end,
	readLine = 	function(script, env, remComments) 
					return handleError(readLine, script, env, remComments)
				end,
	readScript = function(script, env, remComments)
					return handleError(readScript, script, env, remComments == nil or remComments == true, "main", 0)
				end,
	removeComments = removeComments
}
