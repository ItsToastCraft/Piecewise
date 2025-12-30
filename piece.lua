--#region Toast.Defaults

local Logger = { level = 0, levels = -1 } --- only shows warns in prod

local function prettyPrint(name, color, text)
    if not text then return end
    printJson(toJson({
        { text = ("[%s] "):format(name), color = color },
        { text = avatar:getEntityName(), color = "white" },
        { text = " : " .. text .. "\n",  color = color },
    }))
end

local function newLogger(name, color)
    Logger.levels = Logger.levels + 1
    return setmetatable({ level = Logger.levels, name = name, color = color }, {
        __call = function(t, text)
            if (t.level >= Logger.level) then
                prettyPrint(name, color, text)
            end
        end
    })
end

local debug = newLogger("debug", "dark_aqua")
local info = newLogger("info", "green")
local warn = newLogger("warn", "yellow")

local Recolor = pcall(require, "colorable") and require("colorable") or nil
if not Recolor then warn("Colorable module not found, disabling Tintables!") end

local bit32 = bit32

local CURRENT_OUTFIT = {} ---@type Toast.Piece.Type[]
local ALL_PIECES = {} ---@type Toast.Piece.Type[]
local ALL_MODEL_PARTS = {} ---@type table<string, ModelPart>

local EMPTY_VECTOR = vec(0, 0, 0)
local BODY_OFFSET = vec(0, -12, 0)

---@type table<Toast.Part.Type, Vector3> The default offsets for each part type. This is used to determine the offset for the skull position.
local SKULL_OFFSETS = {
    HAT = vec(0, -24, 0),
    BODY_BASE = BODY_OFFSET,
    BODY_LAYER = BODY_OFFSET,
    LEFT_HAND = BODY_OFFSET,
    RIGHT_HAND = BODY_OFFSET,
    PANTS = EMPTY_VECTOR,
    SHOES = EMPTY_VECTOR
}

--#endregion Toast.Defaults

--#region Toast.Piece

---@class Toast.Piece
local Piece = {}
Piece.__index = Piece

function Piece:updateModelParts(parts)
    self.options.modelParts = parts
    for _, part in pairs(self.options.modelParts) do
        ALL_MODEL_PARTS[part:getName()] = ALL_MODEL_PARTS[part:getName()] or part
    end
    return self
end

function Piece.new(self, name, options)
    options = options or {} ---@type Toast.Piece.Options
    options.skullOffset = options.skullOffset or (options.part and SKULL_OFFSETS[options.part]) or EMPTY_VECTOR
    options.modelParts = options.modelParts or {}
    local inst = setmetatable({ name = name, options = options }, { __index = self })
    inst.id = #ALL_PIECES + 1
    ALL_PIECES[inst.id] = inst
    inst:updateModelParts(options.modelParts)
    return inst
end

function Piece.copy(self, name, options)
    local class = getmetatable(self).__index
    local inst = class:new(name, options)
    for option, value in pairs(self.options) do --- Inherits properties from its copy
        inst.options[option] = inst.options[option] or value
    end
    return inst
end

function Piece:serialize(buf)
    buf:writeShort(self.id)
end

function Piece.deserialize(self)
    self:equip()
    return self
end

function Piece:setVisible(visible)
    for _, part in pairs(self.options.modelParts) do
        part:setVisible(visible)
    end
    return self
end

function Piece:equip()
    CURRENT_OUTFIT[#CURRENT_OUTFIT + 1] = self
    self:setVisible(true)
end

--#region Toast.Piece

--#region Toast.Tintable

---@class Toast.TintablePiece: Toast.Piece
local Tintable = setmetatable({}, { __index = Piece })
Tintable.__index = Tintable

---@type table<Toast.TintablePiece.Mode, Toast.TintablePiece.Method>
local tintMethods = {
    SIMPLE = function(piece, value)
        for _, modelPart in pairs(piece.options.modelParts) do
            modelPart:setColor(value)
        end
    end,
    RGB = function(piece, value, layer)
        Recolor.fromRGB(value, piece.options.texture, piece.options.bounds, layer)
    end,
    PALETTE = function(piece, index, layer)
        if not piece.options.palette then return end --- That's on y'all smh I made the instructions clear
        Recolor.remap(index, piece.options.texture, piece.options.bounds, layer)
    end
}

function Tintable:new(name, options)
    local inst = Piece.new(self, name, options)
    inst.tint = tintMethods[inst.options.tintMethod] or tintMethods.SIMPLE
    return inst
end

function Tintable:updateColor(primary, secondary)
    for layer, value in pairs({ PRIMARY = primary, SECONDARY = secondary }) do
        if type(value) == "Vector3" and value == EMPTY_VECTOR then goto continue end
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

if not Recolor then
    setmetatable(Tintable, {
        __index = function(_, _)
            warn(
                "Tintables are disabled! To use them, install the Colorable module from the same Github Repository.")
            return nil
        end
    })
end
--#endregion Toast.Tintable


--#region Toast.Serialized

---Deserializes pieces
---@param str string
local function deserializePieces(str)
    for _, modelPart in pairs(ALL_MODEL_PARTS) do
        modelPart:setVisible(false)
    end

    local buf = data:createBuffer(#str)
    buf:writeByteArray(str)
    buf:setPosition(0)

    repeat
        local piece = ALL_PIECES[buf:read()]
        if not piece then break end --- Reading was somehow corrupted, will wait until the next sync ping
        piece:deserialize(buf)
    until buf:getPosition() >= #str
end

---@param ... Toast.Piece.Type
local function serializeOutfit(...)
    local buf = data:createBuffer(256)
    for _, piece in pairs({ ... }) do
        piece:serialize(buf)
    end
    buf:setPosition(0)
    local output = buf:readByteArray()
    buf:close()
    return output
end

---@param data string
function pings.transfer(data)
    deserializePieces(data)
end

local timer = -20
local function scheduledPing()
    timer = timer + 1
    if timer % 100 == 0 then
        pings.transfer(serializeOutfit(table.unpack(CURRENT_OUTFIT)))
    end
end

local tint = Tintable:new("hello", { primary = 0x973131 })
tint:equip()

events.TICK:register(scheduledPing, "scheduledPing")

--#endregion Toast.Serialized

--#region Toast.Outfit

config:setName("Toast.Outfits_0.0.3")


---@alias Toast.Outfit.Parser fun(self: self, name: string)

local Outfit = {
    cache = config:load("saved") or {},
    ---@type Toast.Outfit.Parser
    save = function(self, name)
        self.cache[name] = serializeOutfit(table.unpack(CURRENT_OUTFIT)) --- SHUT UP I KNOW WHAT'S IN THE TABLE
        config:save("saved", self.cache)
    end,
    ---@type Toast.Outfit.Parser
    load = function(self, name)
        if not self.cache[name] then
            warn(("No outfit found with name '%s'"):format(name))
            return
        end
        pings.transfer(self.cache[name])
    end
}

config:save("saved", Outfit.cache)

Outfit:load("cheese")

--#endregion Toast.Outfit
return { Piece = Piece, Tintable = Tintable, Outfit = Outfit }
