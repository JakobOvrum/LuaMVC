local luamvc = require "luamvc"
local luaweb = require "luaweb"

local mvc = luamvc.new(arg[1] or ".")

local server = luaweb.new{
		port = 80;
		callback = function(req) mvc:handle(req) end;
	}

server:run()
