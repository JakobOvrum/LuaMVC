local setmetatable = setmetatable
local insert = table.insert
local concat = table.concat
local unpack = unpack
local pairs = pairs
local pcall = pcall
local assert = assert
local setfenv = setfenv

local print = print

local loader = require "luamvc.loader"

module "luamvc"

local mvc = {}
mvc.__index = mvc

function new(path)
	local self = setmetatable({
		path = path;
		controllers = loader.controllers(path .. "/controllers");
		views = loader.views(path .. "/views");
	}, mvc)
	
	return self
end

local function parsePath(path)
	local parts = {}
	path:gsub("([^/]+)/?", function(part) insert(parts, part) end)
	return unpack(parts)
end

function mvc:handle(req)
	local request = {
		serveText = function(fmt, ...)
			req:reply{
				status = 200; 
				headers = {["Content-Type"] = "text/html"};
				body = fmt:format(...);
			}
		end;

		serveError = function(code, message)
			req:reply{
				status = code;
				body = message;
			}
		end;
	}
	
	local succ, err = pcall(self.serve, self, request, parsePath(req.path))
	if not succ then
		request.serveError(500, self.views.error{message = err})
	end
end

function mvc:serve(request, controller, action, ...)
	controller = controller or "index"
	action = action or "index"
	
	local f = assert(self.controllers[controller], concat{"controller \"", controller, "\" not found"})[action]
	
	setfenv(assert(f, concat{"action \"", action, "\" not found"}), request)
	
	f(...)
end

