--#region Toast.Defaults
local Logger = require("utils").Logger

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

function Piece:setUV()
    for _, value in pairs(self.options.modelParts) do
        if self.options.texture then
            value:setPrimaryTexture("CUSTOM", self.options.texture)
        end
        if self.options.bounds then
            value:setUVPixels(self.options.bounds.xy)
        end
    end
end

function Piece:equip()
    Logger.debug(("%s has been equipped"):format(self.name))
    CURRENT_OUTFIT[self.id] = self
    self:setVisible(true)
end

function Piece:unequip()
    CURRENT_OUTFIT[self.id] = nil
    self:setVisible(false)
end

--#region Toast.Piece

--#region Toast.Serialized

---Deserializes pieces
---@param str string
local function deserializePieces(str)
    for _, modelPart in pairs(ALL_MODEL_PARTS) do
        modelPart:setVisible(false)
    end
    for id, piece in pairs(CURRENT_OUTFIT) do
        piece:unequip()
    end
    local buf = data:createBuffer(#str)
    buf:writeByteArray(str)
    buf:setPosition(0)

    repeat
        local piece = ALL_PIECES[buf:readShort()]
        if not piece then break end --- Reading was somehow corrupted, will wait until the next sync ping
        piece:deserialize(buf)
    until buf:getPosition() >= #str
    buf:close()
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
    if not host:isHost() then
        deserializePieces(data) --- The host already ran the operations
    end
end

local timer = -20
local function scheduledPing()
    timer = timer + 1
    if timer % 100 == 0 then
        pings.transfer(serializeOutfit(table.unpack(CURRENT_OUTFIT)))
    end
end

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
        return self.cache[name]
    end,
    ---@type Toast.Outfit.Parser
    load = function(self, name)
        if not self.cache[name] then
            Logger.debug(("No outfit found with name '%s', ignoring"):format(name))
            return
        end
        pings.transfer(self.cache[name])
    end
}

config:save("saved", Outfit.cache)

--#endregion Toast.Outfit
return Piece, Outfit
