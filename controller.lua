local lfs = require "lfs"

local setmetatable = setmetatable
local rawget = rawget
local setfenv = setfenv
local assert = assert
local loadfile = loadfile
local xpcall = xpcall
local pcall = pcall
local loadstring = loadstring
local concat = table.concat
local insert = table.insert
local open = io.open
local attributes = lfs.attributes
local time = os.time
local error = error
local traceback = debug.traceback
local unpack = unpack

local viewLoader = require "luamvc.view"

module "luamvc.controller"

local function lastModified(path)
    return assert(lfs.attributes(path)).modification
end

function load(contDir, viewDir)
    local controllers = {}
    
    for fileName in lfs.dir(contDir) do
        local name = fileName:match("(.+)%.lua$")
        if name then
            controllers[name] = new(name, concat{contDir, "/", fileName}, concat{viewDir, "/", name})
        end
    end

    return controllers
end

local controller = {}
controller.__index = controller

function new(name, path, viewDir)
    local self = {
        name = name;
        path = path;
        viewDir = viewDir;
    }
    setmetatable(self, controller)

    self:load()
    
    return self
end

function controller:load()
    self.timestamp = time()
    local f, err = loadfile(self.path)
    if not f then
        error(("failed loading controller \"%s\": %s"):format(self.name, err), 0)
    end

    local env = {}
    setfenv(f, env)

    local succ, err = pcall(f)
    if not succ then
        error(("failed loading controller \"%s\": %s"):format(self.name, err), 0)
    end

    self.actions = env 
end

function controller:reload()
    local modTime = lastModified(self.path)
    if modTime > self.timestamp then
        self:load()
    end
end

function controller:view(name)
    local path = concat{self.viewDir, "/", name, ".iua"}
    return viewLoader.load(path)
end

function controller:run(action, env, ...)
    self:reload()

    local function raise(b, errormsg, code)
        if not b then
            error({
                code = code or 500;
                message = ("error running action \"%s\" for controller \"%s\""):format(action, self.name);
                trace = errormsg;
            }, 0)
        end
        return b, errormsg
    end
    
    local f = raise(self.actions[action], "action not defined", 404)
    setfenv(f, env)

    local args = {...}
	raise(xpcall(function() f(unpack(args)) end, traceback))

    local succ, view = raise(xpcall(function() return self:view(action) end, traceback))
    local succ, output = raise(xpcall(function() return view(env) end, traceback))
    
    return output
end

