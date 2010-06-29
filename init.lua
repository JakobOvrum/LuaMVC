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
local stderr = io.stderr
local xpcall = xpcall

local controller = require "luamvc.controller"
local view = require "luamvc.view"
local response = require "luamvc.response"

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
	local resp = response.new(req)

	local succ, err
	if self.debug then
	    succ, err = xpcall(function() self:serve(resp, parsePath(req.path)) end, traceback)
    else
        succ, err = pcall(self.serve, self, resp, parsePath(req.path))
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

        if resp.hasReplied() then
            stderr:write(("late error %d: %s"):format(code, message))
            if errormsg then
                stderr:write(errormsg)
                stderr:write("\r\n")
            end
        else
            resp.serveError(code, self.errorView{
                code = code;
                message = message;
                trace = errormsg;
            })
        end
    end
end

function mvc:serve(resp, controller, action, ...)
	controller = controller or "index"
	action = action or "index"
	
	local c = self.controllers[controller]
	if not c then
	    error({
	        code = 404;
	        message = ("controller \"%s\" not defined"):format(controller)
	    }, 0)
	end

    c:run(action, resp, ...)
end

