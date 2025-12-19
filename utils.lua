local utils = {}
-- Recursively copies a table (thanks 4P5)
---@param orig table The original table to copy.
---@return table copy A copy of the table.
function utils.deepCopy(orig)
    if utils.rawtype(orig) ~= "table" then return orig end
    local copy = {}
    for k, v in pairs(orig) do
        copy[k] = utils.deepCopy(v)
    end
    return copy
end

return utils
