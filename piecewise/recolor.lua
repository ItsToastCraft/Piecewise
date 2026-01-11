local utils = require("./utils")


---@class Toast.Recolor
local Recolor = {}

---@type table<AvatarAPI.permissionLevel, integer>
local INSTRUCTION_REGIONS = {
    LOW = 8,
    DEFAULT = 4,
    HIGH = 2,
    MAX = 1,
}

function Recolor.serializeColor(value, buf)
    value = Recolor.remapTo(value, "INT") ---@cast value integer
    buf:write(bit32.band(bit32.rshift(value, 16), 0xFF))
    buf:write(bit32.band(bit32.rshift(value, 8), 0xFF))
    buf:write(bit32.band(value, 0xFF))
end

function Recolor.deserializeColor(buf)
    local col = vec(buf:read(), buf:read(), buf:read()) / 255
    utils.Logger.debug("Deserialized to hex code", vectors.rgbToHex(col))
    return col
end

function Recolor.randomColor()
    return vec(math.random(), math.random(), math.random())
end

function Recolor.splitTexture(tex, bounds, func)
    local divisions = INSTRUCTION_REGIONS[avatar:getPermissionLevel()]
    local x, y, w, h = bounds:unpack()

    local cellW = math.floor(w / divisions)
    local cellH = math.floor(h / divisions)

    for i = 0, (divisions * divisions) - 1 do
        local col = i % divisions
        local row = math.floor(i / divisions)

        local ox = col * cellW
        local oy = row * cellH

        --- last row/column absorbs remainder pixels
        local cw = (col == divisions - 1) and (w - ox) or cellW
        local ch = (row == divisions - 1) and (h - oy) or cellH

        utils.runLater(i, function()
            tex:applyFunc(x + ox, y + oy, cw, ch, func) ---@diagnostic disable-line: param-type-mismatch
        end)
    end

    utils.runLater(divisions * divisions + 5, function()
        tex:update()
    end)
end

---@type table<Toast.Recolor.RemapMode, table<Toast.Recolor.RemapMode, fun(value): Toast.Recolor.Remappable>>
local remapModes = {
    RGB = { HEX = function(value) return vectors.hexToRGB(value) end, INT = function(value) return vectors.intToRGB(value) end },
    INT = { HEX = function(value) return vectors.rgbToInt(vectors.hexToRGB(value)) end, RGB = function(value) return vectors.rgbToInt(value) end },
    HEX = { INT = function(value) return vectors.rgbToHex(vectors.intToRGB(value)) end, RGB = function(value) return vectors.rgbToHex(value) end }
}

function Recolor.remapTo(value, mode)
    local valType = type(value)
    local valMode = (valType == "number" and "INT") or (valType == "Vector3" and "RGB") or (valType == "string" and "HEX") or nil ---@type Toast.Recolor.RemapMode?
    if not valMode then error("Wtf are you trying to remap???") end

    if valMode == mode then return value end
    return remapModes[mode][valMode](value)
end
function Recolor.mapPaletteToRGB(palette)
    for key, value in pairs(palette) do
        local rgb = Recolor.remapTo(value, "RGB")  ---@cast rgb Vector3
        palette[key] = rgb:augmented(1) ---@diagnostic disable-line assign-type-mismatch
    end
end

---@type Vector.applyFunc
local clampVector = function (value, _) return math.clamp(value, 0, 1) end --- My Kotlin lambda variables :sob:
   
---Actually quite proud of this
function Recolor.generatePalette(input)
    input = Recolor.remapTo(input, "RGB") ---@cast input Vector3
    local palette = { input:augmented() }
    local color = vectors.rgbToHSV(input.xyz)

    local hueOffset, satOffset, valueOffset = 1, 1, 1 ---@type number, number, number SHUT UP

    hueOffset = (color.x < 0.2 or color.x > 0.68) and 5 or -5  --- Reds
    valueOffset = (color.z > 0.8 or color.z < 0.23) and 6 or 4 --- dark colors
    satOffset = (color.y > 0.8) and 3 or 5                     --- Hypersaturated

    if color.y < 0.2 then                                      --- Grays
        satOffset = 0.7
    elseif color.y < 0.65 or color.y > 0.9 then                --- Mids
        satOffset = 3
        valueOffset = valueOffset + 1
    else                                                       --- Hypersaturateds again
        satOffset = 5
    end
    if 0.25 < color.x and color.x < 0.43 then --- Limes/Greens go towards blue
        hueOffset = hueOffset + 2
        valueOffset = valueOffset + 2
    elseif 0.6 < color.x and color.x < 0.66 then --- Blues
        hueOffset = hueOffset - 0.5
        satOffset = satOffset - 1
        valueOffset = valueOffset + 2
    elseif 0.68 < color.x and color.x < 0.72 then -- Purples also go towards blue
        hueOffset = hueOffset * -1
    end

    local offset = vec(hueOffset / 360, -satOffset / 100, valueOffset / 100)
    for i = 1, 4 do --- I do 4 extra colors (5 total) cause that's my design philosophy, you could probably do more but it'll approach #000000 quickly
        if color.y >= 1 then valueOffset = -valueOffset end

        color = color.xyz - offset
        palette[i + 1] = vectors.hsvToRGB(color:applyFunc(clampVector)):augmented()
    end
    return palette
end

return Recolor