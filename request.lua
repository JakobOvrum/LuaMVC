local rawget = rawget
local error = error
local tostring = tostring
local type = type
local setmetatable = setmetatable
local concat = table.concat

local _G = _G

module "luamvc.request"

local request = {}
request.__index = _G
--[[function request:__index(key)
	local v = rawget(self, key)
	if v == nil then
		v = rawget(_G, key)
		
		if v == nil then
			error(concat{"undefined variable \"", tostring(key), "\""}, 2)
		end
	end
	return v
end]]

function new(req)
	local self = {served = false}
	function self.serveText(fmt, ...)
		if type(fmt) ~= "string" then
			error("arg #1 expected string, got " .. type(fmt), 2)
		end
		
		req:reply{
			status = 200; 
			headers = {["Content-Type"] = "text/html"};
			body = fmt:format(...);
		}
		request.served = true
	end

	function self.serveError(code, message)
		req:reply{
			status = code;
			body = message;
		}
		request.served = true
	end
	
	return setmetatable(self, request)
end
