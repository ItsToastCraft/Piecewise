--#region Toast.Colorable

---@class Color: Toast.Serializeable
local Recolor = {}

--- Colors meant to be replaced when using a `TintablePiece`, add more if you use more than 5 colors per piece (you criminal)
local DEFAULT_REPLACEMENTS = {
    PRIMARY = {["f3f3f3"] = 1, ["e7e7e7"] = 2, ["cdcdcd"] = 3, ["b4b4b4"] = 4, ["9b9b9b"] = 5},
    SECONDARY = {["808080"] = 1, ["666666"] = 2, ["4d4d4d"] = 3, ["333333"] = 4, ["1a1a1a"] = 5}
}



---@class Toast.HexColor: Toast.Serializeable
local Hex = {
    deserialize = function(self, data) end,
}
---@param hex string | number either 6 char hex code or the integer value
function Hex:serialize(hex)
    hex = tonumber(hex)

    local newHex = vec(
        bit32.rshift(hex, 16),
        bit32.band(bit32.rshift(hex, 8), 0xFF),
        bit32.band(hex, 0xFF)
    ):div(17):floor()

    return tostring(bit32.bor(bit32.lshift(newHex.r, 8), bit32.lshift(newHex.g, 4), newHex.b))
end

local function generatePalette(hex)
    
    local pal = {vectors.hexToRGB(hex):augmented(1)}
    local hueOffset, satOffset, valueOffset = 1, 1, 1
    hueOffset = (color.x < 0.2 or color.x > 0.68) and 5 or -5

    valueOffset = (color.z > 0.8 or color.z < 0.23) and 6 or 4
    satOffset = (color.y > 0.8) and 3 or 5
    if color.y < 0.65 or color.y > 0.9 then
        satOffset = 3
        valueOffset = valueOffset + 1
    else
        satOffset = 5
    end
    if 0.25 < color.x and color.x < 0.43 then
        hueOffset = hueOffset + 2
        valueOffset = valueOffset + 2
    elseif 0.6 < color.x and color.x < 0.66 then
        hueOffset = hueOffset - 0.5
        satOffset = satOffset - 1
        valueOffset = valueOffset + 2
    elseif 0.68 < color.x and color.x < 0.72 then
        hueOffset = hueOffset * -1
    end

    local offset = vec(hueOffset / 360, -satOffset / 100, valueOffset / 100)
    for i = 1, 4 do
        if color.y >= 1 then valueOffset = -valueOffset end
        color = color - offset
        pal[i + 1] = vectors.hsvToRGB(math.clamp(color.x, 0, 1), math.clamp(color.y, 0, 1),
            math.clamp(color.z, 0, 1)):augmented()
        
    end
end

function Recolor.hex() end