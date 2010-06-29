local type = type
local error = error
local getinfo = debug.getinfo

module "luamvc.util"

function checkArg(argn, expectedType, arg)
    local t = type(arg)
    if t ~= expectedType then
        local name = getinfo(2, "n").name
        error(("bad argument #%d to %s (%s expected, got %s)"):format(argn, name, expectedType, t), 3)
    end

    return arg
end

