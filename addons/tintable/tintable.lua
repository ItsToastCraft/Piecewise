local Logger = require("./utils").Logger
local Recolor = require("./recolor") ---@type Toast.Recolor
local Piece = require("./piece") ---@type Toast.Piece

---@class Toast.Tintable: Toast.Piece
local Tintable = setmetatable({}, { __index = Piece })
Tintable.__index = Tintable

--#region Toast.Defaults

local EMPTY_VECTOR = vectors.vec3()


--- Colors meant to be replaced when using a `Tintable`, add more if you use more than 5 colors per piece (you criminal)
---@type table<Toast.Layer, Toast.Recolor.Palette>
local DEFAULT_MASK = { ---@diagnostic disable-line assign-type-mismatch
    PRIMARY = { ["f3f3f3"] = 1, ["e7e7e7"] = 2, ["cdcdcd"] = 3, ["b4b4b4"] = 4, ["9b9b9b"] = 5 },
    SECONDARY = { ["808080"] = 1, ["666666"] = 2, ["4d4d4d"] = 3, ["333333"] = 4, ["1a1a1a"] = 5 },
} 

--#endregion Toast.Defaults


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

---@type Toast.Tintable.BuiltinFuncs
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
    local inst = Piece.new(self, name, options) ---@type Toast.Tintable
    inst.tint = tintMethods[inst.options.tintMethod or "SIMPLE"]
    if options.tintMethod == "PALETTE" and not options.palette then
        Logger.warn("No palette found for " .. name.. ", reverting to SIMPLE tint mode.")
        inst.tint = tintMethods.SIMPLE
    elseif options.palette and type(options.palette[1][1]) == "string" then
        for _, value in ipairs(options.palette) do
            Recolor.mapPaletteToRGB(value)
        end
    end
    return inst
end

function Tintable:reset()
    self.options.primary = 0
    self.options.secondary = 0
    if self.options.texture then 
        self.options.texture:restore():update()
    end
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
            ---@cast value integer
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
        buf:write(bit32.bor(
        bit32.lshift(options.primary or 0, 4) or 0, 
        options.secondary or 0)
        )
    else
        local primary, secondary = options.primary, options.secondary
        local flag = (primary ~= 0 and 1 or 0) + (secondary ~= 0 and 2 or 0)
        buf:write(flag)
        if primary and primary ~= 0 then
            Recolor.serializeColor(primary, buf)
        end
        if secondary and secondary ~= 0 then
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

return Tintable