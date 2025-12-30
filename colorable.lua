local runLater = require("runLater")

--#region

---@generic K, V
---@param tab table<K, V>
---@return { [V]: K }
function SwapValues(tab)
    local output = {}
    for id, name in pairs(tab) do
        output[name] = id
    end
    return output
end

---A list of colors indexed by their hex value.
---@alias Toast.Palette table<string, integer> | RGB[]

--#region Toast.Defaults

---Default Palettes for the 16 indexed colors
---@type table<Toast.IndexedColors, Vector4>
local DEFAULT_PALETTE = {
    RED = { "843612" },
    ORANGE = { "e15a25" },
    YELLOW = { "f9ca24" },
    LIME = { "88bd0d" },
    GREEN = { "60a220" },
    LIGHT_BLUE = { "3fc4dc" },
    CYAN = { "4bd5cf" },
    BLUE = { "3879e3" },
    PURPLE = { "8f27d1" },
    MAGENTA = { "a429ca" },
    PINK = { "f88da7" },
    BROWN = { "7f431a" },
    LIGHT_GRAY = { "dbdbdb" },
    GRAY = { "babcbd" },
    BLACK = { "181a1f" },
    WHITE = { "ffffff" },
}
---@alias Toast.Layer
---| "PRIMARY"
---| "SECONDARY"


--- Colors meant to be replaced when using a `TintablePiece`, add more if you use more than 5 colors per piece (you criminal)
---@type table<Toast.Layer, Toast.Palette>
local DEFAULT_MASK = {
    PRIMARY = { ["f3f3f3"] = 1, ["e7e7e7"] = 2, ["cdcdcd"] = 3, ["b4b4b4"] = 4, ["9b9b9b"] = 5 },
    SECONDARY = { ["808080"] = 1, ["666666"] = 2, ["4d4d4d"] = 3, ["333333"] = 4, ["1a1a1a"] = 5 },
}

---Default names of colors (aka. dye system)
---@enum (key) Toast.IndexedColors
local DEFAULT_COLORS = {
    RED = 1,
    ORANGE = 2,
    YELLOW = 3,
    LIME = 4,
    GREEN = 5,
    LIGHT_BLUE = 6,
    CYAN = 7,
    BLUE = 8,
    PURPLE = 9,
    MAGENTA = 10,
    PINK = 11,
    BROWN = 12,
    LIGHT_GRAY = 13,
    GRAY = 14,
    BLACK = 15,
    WHITE = 16,
}
local COLOR_TO_INT = SwapValues(DEFAULT_COLORS)


--#endregion Toast.Defaults


local band = bit32.band
local rshift = bit32.rshift

---@alias RGB Vector3


local Recolor = {}

---@param hex RGB|integer
function Recolor.serializeColor(hex, buf)
    if type(hex) == "number" then hex = vectors.intToRGB(hex) end ---@cast hex RGB
    hex = (hex * 255):floor()
    buf:write(hex.r)
    buf:write(hex.g)
    buf:write(hex.b)
end

---@param buf Buffer
---@return RGB
function Recolor.deserializeColor(buf)
    return vec(buf:read(), buf:read(), buf:read()) / 255
end

---Splits a texture into 4 quadrants
---@param tex Texture
---@param bounds Vector4
---@param func Texture.applyFunc
local function splitTexture(tex, bounds, func)
    local x, y, w, h = bounds:unpack()
    ---(IF YOU DON'T SET A REGION PROPERLY, DISRESPECTFULLY EXPLODE CAUSE I DON'T WANNA SEE NO COMPLAINTS WHEN Y'ALL TRY TINTING A 256x256 TEXTURE LIKE IT'S NOTHING OK????)
    local halfW, halfH = math.ceil(w / 2), math.ceil(h / 2)

    for i = 0, 3 do
        local ox = (i % 2) * halfW
        local oy = math.floor(i / 2) * halfH
        runLater(i * 2,
            function() tex:applyFunc(x + ox, y + oy, halfW, halfH, func) end)
    end
end

---Generates a palette from a starting color.
---
--- ! EXPERIMENTAL ! - I still need to tweak the values,
--- and the colors produced are highly stylized to look like mine, so tweak this yourself for different results!
---@param input RGB
---@return Toast.Palette
local function generatePalette(input)
    local palette = { input:augmented(1) }
    local color = vectors.rgbToHSV(palette[1].xyz)

    local hueOffset, satOffset, valueOffset = 1, 1, 1

    hueOffset = (color.x < 0.2 or color.x > 0.68) and 5 or -5
    valueOffset = (color.z > 0.8 or color.z < 0.23) and 6 or 4
    satOffset = (color.y > 0.8) and 3 or 5

    if color.y < 0.2 then
        satOffset = 0.7
    elseif color.y < 0.65 or color.y > 0.9 then
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
    for i = 1, 4 do --- I do 4 extra colors (5 total) cause that's my design philosophy, you could probably do more but it'll approach #000000 quickly
        if color.y >= 1 then valueOffset = -valueOffset end

        color = color.xyz - offset ---@cast color Vector3

        palette[i + 1] = vectors.hsvToRGB(color:applyFunc(function(value, _)
            return math.clamp(value, 0, 1)
        end)):augmented()
    end
    return palette
end

for color, initial in pairs(DEFAULT_PALETTE) do
    DEFAULT_PALETTE[color] = generatePalette(vectors.hexToRGB(initial[1])) ---@diagnostic disable-line
end

return Recolor
