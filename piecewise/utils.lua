---@class Toast.Utils
local utils = {}

---- Run Later by manuel_2867 ----
local tmrs = {}
local t = 0
function utils.runLater(ticks, next)
    local x = type(ticks) == "number"
    table.insert(tmrs, { t = x and t + ticks, p = x and function() end or ticks, n = next })
end

function events.TICK()
    t = t + 1
    for key, timer in pairs(tmrs) do
        if timer.p() or (timer.t and t >= timer.t) then
            timer.n()
            tmrs[key] = nil
        end
    end
end

---Prints stuff nicely
---@param name string
---@param color string
---@param ... any
local function prettyPrint(name, color, ...)
    if not ... then return end

    local json = {
        { text = ("[%s] "):format(name), color = color },
        { text = avatar:getEntityName(), color = "white" },
        { text = " : ",                  color = color },
    }
    for _, value in ipairs({ ... }) do
        if type(value) ~= "string" then value = tostring(value) end
        table.insert(json, { text = value .. " ", color = color })
    end
    table.insert(json, { text = "\n" })
end

local Logger = { level = 2, levels = -1 } --- only shows warns in prod

function utils.newLogger(name, color)
    Logger.levels = Logger.levels + 1
    return setmetatable({ level = Logger.levels, name = name, color = color }, {
        __call = function(tab, ...)
            if not host:isHost() then return end
            if (tab.level >= Logger.level) then
                prettyPrint(name, color, ...)
            end
        end,
    })
end

function utils.transferElements(from, to)
    for key, element in from do
        to[key] = element
    end
end

function utils.stringHash(str)
    local hash = 0x811C9DC5
    for i = 1, #str do
        hash = bit32.bxor(hash, str:byte(i))
        hash = (hash * 0x01000193) % 0xFFFFFFFF
    end
    return bit32.band(hash, 0xFFFFFF)
end

function utils.swapValues(tab)
    local output = {}
    for id, name in pairs(tab) do
        output[name] = id
    end
    return output
end

Logger.debug = utils.newLogger("debug", "dark_aqua")
Logger.info = utils.newLogger("info", "green")
Logger.warn = utils.newLogger("warn", "yellow")

utils.Logger = Logger

return utils
