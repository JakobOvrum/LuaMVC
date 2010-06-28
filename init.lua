local setmetatable = setmetatable
local insert = table.insert
local concat = table.concat
local unpack = unpack
local pairs = pairs
local pcall = pcall
local assert = assert
local type = type
local error = error
local setfenv = setfenv
local traceback = debug.traceback
local xpcall = xpcall

local _G = _G

local loader = require "luamvc.loader"
local request = require "luamvc.request"

module "luamvc"

local mvc = {}
mvc.__index = mvc

function new(path, debug)
    if debug == nil then
        debug = true
    end
    
	local self = setmetatable({
		path = path;
		controllers = loader.controllers(path .. "/controllers");
		views = loader.views(path .. "/views");
		errorView = loader.view("error", path .. "/internal/error.iua");
		debug = debug;
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

	local succ, err, trace
	if self.debug then
	    succ, err = xpcall(
	        function() self:serve(r, parsePath(req.path)) end, 
	        function(msg) trace = traceback("", 2):sub(2) return msg end
	    )
    else
        succ, err = pcall(self.serve, self, r, parsePath(req.path))
    end
    
    if not succ then
        local code, message
        
        if type(err) == "table" then
            code, message = err.code, err.message
        else
            code, message = 500, self.debug and err or "500 Internal Server Error"
        end

        
        r.serveError(code, self.errorView{
            code = code;
            message = message;
            trace = trace;
        })
    end
end

function mvc:serve(r, controller, action, ...)
	controller = controller or "index"
	action = action or "index"
	
	local f = self.controllers[controller][action]

	if not f then
	    error({
	        code = 404;
	        message = concat{"action \"", action, "\" not defined for controller \"", controller, "\""};
	    }, 0)
	end
	
	setfenv(f, r)

	f(...)

	if not r.served then
		local view = assert(self.views[controller][action], concat{"view \"", controller, "/", action, ".iua\" not found"}) 
		r.serveText(view(r))
	end
end

