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

local controller = require "luamvc.controller"
local view = require "luamvc.view"
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
		controllers = controller.load(path .. "/controllers", path .. "/views");
		errorView = view.load(path .. "/internal/error.iua");
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

	local succ, err
	if self.debug then
	    succ, err = xpcall(
	        function() self:serve(r, parsePath(req.path)) end, 
	        traceback
	    )
    else
        succ, err = pcall(self.serve, self, r, parsePath(req.path))
    end
    
    if not succ then
        local code, message, errormsg
        
        if type(err) == "table" then
            code, message = err.code, err.message
            errormsg = err.trace
        else
            code, message = 500, "500 Internal Server Error"
            if self.debug then
                errormsg = err
            end
        end

        r.serveError(code, self.errorView{
            code = code;
            message = message;
            trace = errormsg;
        })
    end
end

function mvc:serve(r, controller, action, ...)
	controller = controller or "index"
	action = action or "index"
	
	local c = self.controllers[controller]
	if not c then
	    error({
	        code = 404;
	        message = ("controller \"%s\" not defined"):format(controller)
	    }, 0)
	end

    local output = c:run(action, r, ...)

    r.serveText(output)
end

