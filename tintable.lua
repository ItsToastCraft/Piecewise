local utils = require("utils")
local Piece = require("piece")

---@class Toast.TintablePiece: Toast.Piece
local Tintable = setmetatable({}, { __index = Piece })
Tintable.__index = Tintable

--#region Toast.Defaults

local INSTRUCTION_REGIONS = {
    LOW = 8,
    DEFAULT = 4,
    HIGH = 2,
    MAX = 1,
}

local EMPTY_VECTOR = vec(0, 0, 0)

--- Colors meant to be replaced when using a `TintablePiece`, add more if you use more than 5 colors per piece (you criminal)
---@type table<Toast.Layer, Toast.Palette>
local DEFAULT_MASK = {
    PRIMARY = { ["f3f3f3"] = 1, ["e7e7e7"] = 2, ["cdcdcd"] = 3, ["b4b4b4"] = 4, ["9b9b9b"] = 5 },
    SECONDARY = { ["808080"] = 1, ["666666"] = 2, ["4d4d4d"] = 3, ["333333"] = 4, ["1a1a1a"] = 5 },
}

--#endregion Toast.Defaults

---@class Toast.Recolor
local Recolor = {}

function Recolor.serializeColor(hex, buf)
    if type(hex) == "Vector3" then hex = vectors.rgbToInt(hex) end ---@cast hex integer
    buf:write(bit32.band(bit32.rshift(hex, 16), 0xFF))
    buf:write(bit32.band(bit32.rshift(hex, 8), 0xFF))
    buf:write(bit32.band(hex, 0xFF))
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

        -- last row/column absorbs remainder pixels
        local cw = (col == divisions - 1) and (w - ox) or cellW
        local ch = (row == divisions - 1) and (h - oy) or cellH

        utils.runLater(i, function()
            tex:applyFunc(x + ox, y + oy, cw, ch, func)
        end)
    end

    utils.runLater(divisions * divisions + 5, function()
        tex:update()
    end)
end

function Recolor.mapHexToRGB(palette)
    for key, value in pairs(palette) do
        palette[key] = vectors.hexToRGB(value):augmented(1)
    end
end

---Actually quite proud of this
function Recolor.generatePalette(input)
    if type(input) == "number" then
        input = vectors.intToRGB(input)
    elseif type(input) == "Vector3" then
        input = input:augmented(1)
    end
    local palette = { input }
    local color = vectors.rgbToHSV(palette[1].xyz)

    local hueOffset, satOffset, valueOffset = 1, 1, 1

    hueOffset = (color.x < 0.2 or color.x > 0.68) and 5 or -5  --- Reds
    valueOffset = (color.z > 0.8 or color.z < 0.23) and 6 or 4 --- dark colors
    satOffset = (color.y > 0.8) and 3 or 5                     --- Hypersaturated

    if color.y < 0.2 then                                      --- Grays
        satOffset = 0.7
    elseif color.y < 0.65 or color.y > 0.9 then                --- Mids
        satOffset = 3
        valueOffset = valueOffset + 1
    else --- Hypersaturateds again
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

        color = color.xyz - offset ---@cast color Vector3

        palette[i + 1] = vectors.hsvToRGB(color:applyFunc(function(value, _)
            return math.clamp(value, 0, 1)
        end)):augmented()
    end
    return palette
end

local function apply(color, inPalette, layer)
    local match = inPalette[layer[vectors.rgbToHex(color.xyz)]]
    if match then
        return match
    end
end

local function remap(color, tex, bounds, layer)
    local inPalette = type(color) == "table" and color or Recolor.generatePalette(color)
    Recolor.splitTexture(tex, bounds,
        function(col, _, _) return apply(col, inPalette, DEFAULT_MASK[layer]) end)
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
    COLOR = function(piece, value, layer)
        remap(value, piece.options.texture, piece.options.bounds, layer)
        piece.options[layer:lower()] = value
    end,
    PALETTE = function(piece, index, layer)
        if not piece.options.palette then return end --- That's on y'all smh I made the instructions clear
        remap(piece.options.palette[index], piece.options.texture, piece.options.bounds, layer)
        piece.options[layer:lower()] = index
    end,
}

function Tintable:new(name, options)
    options.primary = 0
    options.secondary = 0
    local inst = Piece.new(self, name, options) ---@cast inst Toast.TintablePiece
    inst.tint = tintMethods[inst.options.tintMethod] or tintMethods.SIMPLE
    if options.tintMethod == "PALETTE" and not options.palette then
        utils.Logger.warn("No palette found, reverting to SIMPLE tint mode.")
        inst.tint = tintMethods.SIMPLE
    elseif options.palette and type(options.palette[1][1]) == "string" then
        for _, value in ipairs(options.palette) do
            Recolor.mapHexToRGB(value)
        end
    end
    return inst
end

function Tintable:reset()
    self.options.primary = 0
    self.options.secondary = 0
    self.options.texture:restore():update()
end

function Tintable:setColor(primary, secondary)
    self:setUV()
    local reset = false
    for layer, value in pairs({ PRIMARY = primary, SECONDARY = secondary }) do
        if not value then
            goto continue
        elseif type(value) == "Vector3" and value == EMPTY_VECTOR then
            goto continue
        elseif type(value) == "number" and self.options.tintMethod == "COLOR" then
            value = vectors.intToRGB(value)
        end

        if (value == self.options[layer:lower()]) then goto continue end
        if not reset then
            self:reset()
            reset = not reset
        end

        self:tint(value, layer)
        ::continue::
    end
    return self
end

function Tintable:serialize(buf)
    Piece.serialize(self, buf)
    local options = self.options

    -- These wouldn't need hex codes, but rather table indices (using 1 byte for both, max 16 colors in palette)
    -- If you need more, consider using HEX, or SIMPLE, as you can literally give it a hex
    -- Or modify it to use a full byte
    if (options.tintMethod == "INDEXED") or (options.tintMethod == "PALETTE") then
        buf:write(bit32.bor(bit32.lshift(options.primary or 0, 4) or 0, options.secondary or 0))
    else
        local primary, secondary = options.primary, options.secondary
        local flag = (primary ~= 0 and 1 or 0) + (secondary ~= 0 and 2 or 0)
        buf:write(flag)
        if primary ~= 0 then
            Recolor.serializeColor(primary, buf)
        end
        if secondary ~= 0 then
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
        local byte = buf:read()
        primary = bit32.band(bit32.rshift(byte, 4), 0xF)
        secondary = bit32.band(byte, 0xF)
    else
        local flag = buf:read()
        if bit32.band(flag, 1) ~= 0 then primary = Recolor.deserializeColor(buf) end
        if bit32.band(flag, 2) ~= 0 then secondary = Recolor.deserializeColor(buf) end
    end
    self:setColor(primary, secondary)
    return self
end

--#endregion Toast.Tintable

return Tintable, Recolor
