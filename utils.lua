local utils = {}

---- Run Later by manuel_2867 ----
local tmrs = {}
local t = 0
---Schedules a function to run after a certain amount of ticks
---@param ticks number|function Amount of ticks to wait, or a predicate function to check each tick until it returns true
---@param next function Function to run after amount of ticks, or after the predicate function returned true
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

local function prettyPrint(name, color, text)
    if not text then return end
    printJson(toJson({
        { text = ("[%s] "):format(name), color = color },
        { text = avatar:getEntityName(), color = "white" },
        { text = " : " .. text .. "\n",  color = color },
    }))
end

local Logger = { level = 2, levels = -1 } --- only shows warns in prod

local function newLogger(name, color)
    Logger.levels = Logger.levels + 1
    return setmetatable({ level = Logger.levels, name = name, color = color }, {
        __call = function(tab, text)
            if (tab.level >= Logger.level) then
                prettyPrint(name, color, text)
            end
        end
    })
end

function utils.transferElements(from, to)
    for key, element in from do
        to[key] = element
    end
end

Logger.debug = newLogger("debug", "dark_aqua")
Logger.info = newLogger("info", "green")
Logger.warn = newLogger("warn", "yellow")

utils.Logger = Logger

return utils
