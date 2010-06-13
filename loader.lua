local lfs = require "lfs"

local setmetatable = setmetatable
local rawget = rawget
local setfenv = setfenv
local assert = assert
local loadfile = loadfile
local loadstring = loadstring
local concat = table.concat
local insert = table.insert
local open = io.open

local io = io
local print = print

local _G, error, tostring = _G, error, tostring
local viewEnv = {
	__index = function(o, key)
		local v = rawget(o, key)
		if v == nil then
			v = rawget(_G, key)
			
			if v == nil then
				error(concat{"undefined variable \"", tostring(key), "\""}, 2)
			end
		end
	end
}

module "luamvc.loader"

function controller(path)
	local env = {}
	local f = assert(loadfile(path))
	setfenv(f, env)
	f()
	return env
end

function view(path)
	local f = assert(open(path))
	local source = f:read("*a")
	f:close()
	
	local code, buffer = {}, {}

	local index = 1
	while true do
		local start, stop, echo, snippet = source:find("<%%(=?)(.-)%%>", index)
		insert(code, ("echo[[%s]]"):format(source:sub(index, (start or 0) - 1)))
		if not start then
			break
		end

		if echo:len() == 1 then
			snippet = ("echo(%s)"):format(snippet)
		end
		
		insert(code, snippet)
		
		index = stop + 1
	end

	local code = assert(loadstring(concat(code, "\r\n")))
	
	return function(env)
		local reply = {}

		env.echo = function(str)
			insert(reply, str)
		end
		
		setfenv(code, setmetatable(env, viewEnv))

		code()
		
		return concat(reply)
	end
end

local function load(path, extension, loader)
	local c = {}

	for fileName in lfs.dir(path) do
		local name = fileName:match(concat{"([^%.]+)%.", extension, "$"})
		if name then
			c[name] = loader(concat{path, "/", fileName})
		end
	end

	return c
end

function controllers(path)
	return load(path, "lua", controller)
end

function views(path)
	return load(path, "iua", view)
end