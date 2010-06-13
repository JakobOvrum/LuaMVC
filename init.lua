local setmetatable = setmetatable
local insert = table.insert
local concat = table.concat
local unpack = unpack
local pairs = pairs
local pcall = pcall
local assert = assert
local error = error
local setfenv = setfenv

local _G = _G

local loader = require "luamvc.loader"
local request = require "luamvc.request"

module "luamvc"

local mvc = {}
mvc.__index = mvc

function new(path)
	local self = setmetatable({
		path = path;
		controllers = loader.controllers(path .. "/controllers");
		views = loader.views(path .. "/views");
		errorView = loader.view(path .. "/internal/error.iua");
	}, mvc)
	
	return self
end

local function parsePath(path)
	local parts = {}
	path:gsub("([^/]+)/?", function(part) insert(parts, part) end)
	return unpack(parts)
end

function mvc:handle(req)
	local r = request.new(req)
	
	local succ, err = pcall(self.serve, self, r, parsePath(req.path))
	if not succ then
		r.serveError(500, self.errorView{message = err})
	end
end

function mvc:serve(r, controller, action, ...)
	controller = controller or "index"
	action = action or "index"
	
	local f = assert(self.controllers[controller], concat{"controller \"", controller, "\" not found"})[action]
	
	setfenv(assert(f, concat{"action \"", action, "\" not found"}), r)

	f(...)

	if not r.served then
		local view = assert(self.views[controller][action], concat{"view \"", controller, "/", action, ".iua\" not found"}) 
		r.serveText(view(r))
	end
end

