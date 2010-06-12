local luamvc = require "luamvc"
local luaweb = require "luaweb"

local mvc = luamvc.new(".")

local function handle(sink, command, path, headers, body)
	mvc:handle(sink, command, path, headers, body)
end

local server = luaweb.new{port = 80, callback = handle}

server:run()
