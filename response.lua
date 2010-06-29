local rawget = rawget
local error = error
local tostring = tostring
local type = type
local setmetatable = setmetatable
local concat = table.concat

local _G = _G

local util = require "luamvc.util"

module "luamvc.response"

function new(req)
	local self = {}
    self.params = req.params
	
	function self.serveText(fmt, ...)
	    util.checkArg(1, "string", fmt)
		
		req:reply{
			status = 200; 
			headers = {["Content-Type"] = "text/html"};
			body = fmt:format(...);
		}
	end

	function self.serveError(code, message)
		req:reply{
			status = code;
			body = message;
		}
	end

	function self.hasReplied()
	    return not req:isActive()
	end
	
	return setmetatable(self, {__index = _G})
end
