local utils = require("utils")
local Piece = require("piece")

---@class Toast.TintablePiece: Toast.Piece
local Tintable = setmetatable({}, { __index = Piece })
Tintable.__index = Tintable
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

local INSTRUCTION_REGIONS = {
    LOW = 8,
    DEFAULT = 4,
    HIGH = 2,
    MAX = 1
}

local EMPTY_VECTOR = vec(0, 0, 0)

---@alias Toast.Layer
---| "PRIMARY"
---| "SECONDARY"

--- Colors meant to be replaced when using a `TintablePiece`, add more if you use more than 5 colors per piece (you criminal)
---@type table<Toast.Layer, Toast.Palette>
local DEFAULT_MASK = {
    PRIMARY = { ["f3f3f3"] = 1, ["e7e7e7"] = 2, ["cdcdcd"] = 3, ["b4b4b4"] = 4, ["9b9b9b"] = 5 },
    SECONDARY = { ["808080"] = 1, ["666666"] = 2, ["4d4d4d"] = 3, ["333333"] = 4, ["1a1a1a"] = 5 },
}
-- ! Discontinued for now !
-- ---Default names of colors (aka. dye system)
-- ---@enum (key) Toast.IndexedColors
-- local DEFAULT_COLORS = {
--     RED = 1,
--     ORANGE = 2,
--     YELLOW = 3,
--     LIME = 4,
--     GREEN = 5,
--     LIGHT_BLUE = 6,
--     CYAN = 7,
--     BLUE = 8,
--     PURPLE = 9,
--     MAGENTA = 10,
--     PINK = 11,
--     BROWN = 12,
--     LIGHT_GRAY = 13,
--     GRAY = 14,
--     BLACK = 15,
--     WHITE = 16,
-- }
-- local COLOR_TO_INT = SwapValues(DEFAULT_COLORS)
--
-- ---Default Palettes for the 16 indexed colors
-- ---@type table<Toast.IndexedColors, Vector4>
-- local DEFAULT_PALETTE = {
--     RED = { "843612" },
--     ORANGE = { "e15a25" },
--     YELLOW = { "f9ca24" },
--     LIME = { "88bd0d" },
--     GREEN = { "60a220" },
--     LIGHT_BLUE = { "3fc4dc" },
--     CYAN = { "4bd5cf" },
--     BLUE = { "3879e3" },
--     PURPLE = { "8f27d1" },
--     MAGENTA = { "a429ca" },
--     PINK = { "f88da7" },
--     BROWN = { "7f431a" },
--     LIGHT_GRAY = { "dbdbdb" },
--     GRAY = { "babcbd" },
--     BLACK = { "181a1f" },
--     WHITE = { "ffffff" },
-- }
--#endregion Toast.Defaults

---@alias RGB Vector3

local Recolor = {}

---@param hex RGB|integer
function Recolor.serializeColor(hex, buf)
    if type(hex) == "Vector3" then hex = vectors.rgbToInt(hex) end ---@cast hex integer
    buf:write(bit32.band(bit32.rshift(hex, 16), 0xFF))
    buf:write(bit32.band(bit32.rshift(hex, 8), 0xFF))
    buf:write(bit32.band(hex, 0xFF))
end

---@param buf Buffer
---@return RGB
function Recolor.deserializeColor(buf)
    local col = vec(buf:read(), buf:read(), buf:read()) / 255
    return col
end

---@return RGB
function Recolor.randomColor()
    return vec(math.random(), math.random(), math.random())
end

---Splits a texture into 4 quadrants
---@param tex Texture
---@param bounds Vector4
---@param func Texture.applyFunc
local function splitTexture(tex, bounds, func)
    local divisions = INSTRUCTION_REGIONS[avatar:getPermissionLevel()]
    local x, y, w, h = bounds:unpack()

    local cellW = math.floor(w / divisions)
    local cellH = math.floor(h / divisions)

    for i = 0, (divisions * divisions) - 1 do
        local col = i % divisions
        local row = math.floor(i / divisions)

        local ox = col * cellW
        local oy = row * cellH

        -- last row/column absorbs remainder pixels
        local cw = (col == divisions - 1) and (w - ox) or cellW
        local ch = (row == divisions - 1) and (h - oy) or cellH

        utils.runLater(i, function()
            tex:applyFunc(x + ox, y + oy, cw, ch, func)
        end)
    end

    utils.runLater(divisions * divisions + 5, function()
        tex:update()
        host:setClipboard(tex:save())
    end)
end

-- function vectors.hsvToHex(color)
--     return vectors.rgbToHex(vectors.hsvToRGB(color))
-- end

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

-- for color, initial in pairs(DEFAULT_PALETTE) do
--     DEFAULT_PALETTE[color] = generatePalette(vectors.hexToRGB(initial[1])) ---@diagnostic disable-line
-- end

local function apply(color, inPalette, layer)
    local match = inPalette[layer[vectors.rgbToHex(color.xyz)]]
    if match then
        return match
    end
end

local function remap(color, tex, bounds, layer)
    local inPalette = type(color) == "table" and color or generatePalette(color)
    splitTexture(tex, bounds, function(col) return apply(col, inPalette, DEFAULT_MASK[layer]) end)
end

--#region Toast.Tintable

---@type table<Toast.TintablePiece.Mode, Toast.TintablePiece.Method>
local tintMethods = {
    SIMPLE = function(piece, value)
        for _, modelPart in pairs(piece.options.modelParts) do
            modelPart:setColor(value)
        end
        piece.options.primary = value
    end,
    RGB = function(piece, value, layer)
        remap(value, piece.options.texture, piece.options.bounds, layer)
        piece.options[layer:lower()] = value
    end,
    PALETTE = function(piece, index, layer)
        if not piece.options.palette then return end --- That's on y'all smh I made the instructions clear
        remap(piece.options.palette[index], piece.options.texture, piece.options.bounds, layer)
        piece.options[layer:lower()] = index
    end
}


function Tintable:new(name, options)
    local inst = Piece.new(self, name, options)
    inst.tint = tintMethods[inst.options.tintMethod] or tintMethods.SIMPLE
    if options.tintMethod == "PALETTE" and not options.palette then
        utils.Logger.warn("No palette found, reverting to SIMPLE tint mode.")
        inst.tint = tintMethods.SIMPLE
    end
    return inst
end

function Tintable:reset()
    self.options.primary = 0
    self.options.secondary = 0
    self.options.texture:restore():update()
end

function Tintable:updateColor(primary, secondary)
    self:reset()
    self:setUV()
    for layer, value in pairs({ PRIMARY = primary, SECONDARY = secondary }) do
        if type(value) == "Vector3" and value == EMPTY_VECTOR then
            goto continue
        elseif type(value) == "number" then
            value = vectors.intToRGB(value)
        end
        if (value == self.options[layer:lower()]) then goto continue end
        self:tint(value, layer)

        ::continue::
    end
end

function Tintable:serialize(buf)
    Piece.serialize(self, buf)
    local options = self.options

    -- These wouldn't need hex codes, but rather table indices (using 1 byte for both, max 16 colors in palette)
    -- If you need more, consider using HEX, or SIMPLE, as you can literally give it a hex
    -- Or modify it to use a full byte
    if (options.tintMethod == "INDEXED") or (options.tintMethod == "PALETTE") then
        buf:write(bit32.bor(bit32.rshift(options.primary or 0, 4) or 0, options.secondary or 0))
    else
        local primary, secondary = options.primary, options.secondary
        local flag = (primary ~= 0 and 1 or 0) + (secondary ~= 0 and 2 or 0)
        buf:write(flag)
        if primary then
            Recolor.serializeColor(primary, buf)
        end
        if secondary then
            Recolor.serializeColor(secondary, buf)
        end
    end
end

---@param buf Buffer
function Tintable:deserialize(buf)
    self:equip()
    --- So basically it will always send a color, but the client won't actually recalculate the piece's color unless it actually changed
    --- Cause like what if a client misses it???
    local primary, secondary
    local options = self.options
    if (options.tintMethod == "INDEXED") or (options.tintMethod == "PALETTE") then
        local byte = buf:readShort()
        primary = bit32.band(bit32.lshift(byte, 4), 0xFFFF)
        secondary = bit32.band(byte, 0xFFFF)
    else
        local flag = buf:read()
        if bit32.band(flag, 1) ~= 0 then primary = Recolor.deserializeColor(buf) end
        if bit32.band(flag, 2) ~= 0 then secondary = Recolor.deserializeColor(buf) end
    end
    self:updateColor(primary, secondary)
    return self
end

--#endregion Toast.Tintable

return Tintable, Recolor
