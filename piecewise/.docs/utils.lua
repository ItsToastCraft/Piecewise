---@meta _

---@class Toast.Utils
local utils

---Schedules a function to run after a certain amount of ticks.
---@param ticks number|function Amount of ticks to wait, or a predicate function to check each tick until it returns true
---@param next function Function to run after amount of ticks, or after the predicate function returned true
function utils.runLater(ticks, next) end

---Adds elements from one table to another.
---@param from table
---@param to table
function utils.transferElements(from, to) end

---Hashes a string and returns an integer.
---@return integer
function utils.stringHash(str) end

---Creates a new table where the keys are now the values.
---@generic K, V
---@param tab table<K, V>
---@return { [V]: K }
function utils.swapValues(tab) end

---@alias Toast.Logger fun(...)

---Creates a new logger.
---@param name any
---@param color any
---@return Toast.Logger
function utils.newLogger(name, color) end