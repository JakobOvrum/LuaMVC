local setmetatable = setmetatable

local print = print

module "luamvc"

local mvc = {}
mvc.__index = mvc

function new(path)
	return setmetatable({
		path = path;
	}, mvc)
end

function mvc:handle(sink, command, path, headers, body)
	print(command, path, headers, body)
end
