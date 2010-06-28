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
local error = error

module "luamvc.loader"

function controller(name, path)
	local env = {}
	local f, err = loadfile(path)
	if not f then
	    error({
	        code = 404;
	        message = concat{"controller \"", name, "\" not found: ", err};
	    }, 0)
	end
	
	setfenv(f, env)
	f()
	return env
end

function view(name, path)
	local f, err = open(path)
	if not f then
	    error({
	        code = 404;
	        message = concat{"view \"", name, "\" not found: ", err};
	    }, 0)
	end
	
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

		function env.echo(str)
			insert(reply, str)
		end

		setfenv(code, env)
		code()
		
		return concat(reply)
	end
end

local function load(path, extension, loader)
	local c = setmetatable({}, {
        __index = function(c, name)
            local v = rawget(c, name)
            if v == nil then
                v = loader(name, concat{path, "/", name, ".", extension})
                c[name] = v
            end
            return v
        end
    })

	for fileName in lfs.dir(path) do
		local name = fileName:match(concat{"([^%.]+)%.", extension, "$"})
		if name then
			c[name] = loader(name, concat{path, "/", fileName})
		end
	end

	return c
end

function controllers(path)
	return load(path, "lua", controller)
end

function views(path)
	views = {}
	for name in lfs.dir(path) do
		local p = concat{path, "/", name}
		if lfs.attributes(p).mode == "directory" then
			views[name] = load(p, "iua", view)
		end
	end
	return views
end
