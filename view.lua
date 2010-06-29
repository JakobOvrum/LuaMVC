local lfs = require "lfs"

local setfenv = setfenv
local assert = assert
local loadstring = loadstring
local concat = table.concat
local insert = table.insert
local open = io.open
local time = os.time

module "luamvc.view"

local function lastModified(path)
    return assert(lfs.attributes(path)).modification
end

local cache = {}

function load(path)
    do
        local cached = cache[path]
        if cached and cached.timestamp >= lastModified(path) then
            return cached.f
        end
    end
    
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

	local code = assert(loadstring(concat(code, "\r\n"), "@" .. path:match("([^/\\]+)$")))

	local function run(env)
		local reply = {}

		function env.echo(str)
			insert(reply, str)
		end

		setfenv(code, env)
		code()
		
		return concat(reply)
	end

    cache[path] = {timestamp = time(), f = run}
    
	return run
end
