local moduleName = ...
local M = {}
_G[moduleName] = M

-- Helpers:
function ok(expression, desc)
    if expression == nil then
        expression = true
    end
    desc = desc or 'expression is not ok'
    if not expression then
        error(desc .. '\n' .. debug.traceback())
    end
end

function ko(expression, desc)
    if expression == nil then
        expression = true
    end
    desc = desc or 'expression is not ko'
    ok(not expression, desc)
end

function eq(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) == 'function' then
        return string.dump(a) == string.dump(b)
    end
    if a == b then return true end
    if type(a) ~= 'table' then return false end
    for k,v in pairs(a) do
        if b[k] == nil or not eq(v, b[k]) then return false end
    end
    for k,v in pairs(b) do
        if a[k] == nil or not eq(v, a[k]) then return false end
    end
    return true
end

local function eventuallyImpl(func, retries, delayMs)
    status, err = pcall(func)
    if status then
        M.eventuallyPendingLength = M.eventuallyPendingLength - 1
        M.runNextPending()
    else
        if retries > 0 then
            t = tmr.create()
            t:register(delayMs, 0, M.runNextPending)
            t:start()

            table.insert(M.pending, 1, function() eventuallyImpl(func, retries - 1, delayMs) end)
        else
            print("\n  ' it failed:", err)
            M.eventuallyPendingLength = M.eventuallyPendingLength - 1
            M.runNextPending()
        end
    end
end

function eventually(func, retries, delayMs)
    retries = retries or 10
    delayMs = delayMs or 300

    M.eventuallyPendingLength = M.eventuallyPendingLength + 1

    table.insert(M.pending, M.eventuallyPendingLength, function()
        eventuallyImpl(func, retries, delayMs)
    end)
end

function describe(name, itshoulds)
    M.name = name
    M.itshoulds = itshoulds
end

-- Module:
M.pending = {}
M.eventuallyPendingLength = 0

M.runNextPending = function()
    local next = table.remove(M.pending, 1)
    if next then
        node.task.post(next)
    else
        local elapsedSeconds = (tmr.now() - M.startTime) / 1000 / 1000
        print(string.format('\n\nCompleted in %.2f seconds.', elapsedSeconds))
    end
end

M.run = function()
    M.startTime = tmr.now()
    it = {}
    it.should = function(_, desc, func)
        table.insert(M.pending, function()
            uart.write(0, '\n  * ' .. desc)
            local status, err = pcall(func)
            if not status then
                print("\n  ' it failed:", err)
            end
            M.runNextPending()
        end)
    end
    M.itshoulds(it)

    print('' .. M.name .. ', it should:')
    M.runNextPending()
end
