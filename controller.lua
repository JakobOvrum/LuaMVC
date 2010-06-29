local lfs = require "lfs"

local setmetatable = setmetatable
local rawget = rawget
local setfenv = setfenv
local assert = assert
local loadfile = loadfile
local pcall = pcall
local loadstring = loadstring
local concat = table.concat
local insert = table.insert
local open = io.open
local attributes = lfs.attributes
local time = os.time
local error = error
local print = print

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

    local function raise(b, message, code)
        if not b then
            error({
                code = code or 500;
                message = ("error running action \"%s\": %s"):format(action, message);
            }, 0)
        end
        return b
    end
    
    local f = raise(self.actions[action], "action not defined", 404)
    setfenv(f, env)

    raise(pcall(f, ...))

    local view = raise(pcall(self.view, self, action))

    local output = raise(pcall(view, env))
    
    return output
end
