---@module "piecewise.piece"
--#region Toast.Defaults
local utils = require("./utils")
local Logger = utils.Logger

local CURRENT_OUTFIT = {} ---@generic T: Toast.Piece ---@type T[]
local ALL_PIECES = { count = 0 } ---@generic T: Toast.Piece ---@type {count: integer, [number]: T}
local ALL_MODEL_PARTS = {} ---@type table<string, ModelPart>

local EMPTY_VECTOR = vec(0, 0, 0)
local BODY_OFFSET = vec(0, -12, 0)

---@type table<Toast.Part, Vector3> The default offsets for each part type. This is used to determine the offset for the skull position.
local SKULL_OFFSETS = {
    HAT = vec(0, -24, 0),
    BODY_MAIN = BODY_OFFSET,
    BODY_LAYER = BODY_OFFSET,
    LEFT_HAND = BODY_OFFSET,
    RIGHT_HAND = BODY_OFFSET,
    PANTS = EMPTY_VECTOR,
    SHOES = EMPTY_VECTOR,
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

function Piece:new(name, options)
    options = options or {} ---@type Toast.Piece.Options
    options.skullOffset = options.skullOffset or (options.part and SKULL_OFFSETS[options.part]) or EMPTY_VECTOR
    options.modelParts = options.modelParts or {}
    local inst = setmetatable({ name = name, options = options }, { __index = self })
    inst.id = utils.stringHash(name)
    ALL_PIECES[inst.id] = inst
    ALL_PIECES.count = ALL_PIECES.count + 1
    inst:updateModelParts(options.modelParts)
    return inst
end

function Piece:copy(name, options)
    --- Inherits properties from its copy
    for option, value in pairs(self.options) do
        options[option] = options[option] or value
    end
    local inst = self:new(name, options)
    return inst
end

function Piece:simplify()
    return { name = self.name }
end

function Piece:registerToggle(fun)
    self.onToggle[#self.onToggle + 1] = fun
end

function Piece:serialize(buf)
    buf:writeInt(self.id)
end

function Piece:deserialize(buf)
    self:equip()
    return self
end

function Piece:setVisible(visible)
    for _, part in pairs(self.options.modelParts) do
        part:setVisible(visible)
    end
    if self.visibility ~= visible then self:__toggle() end
    self.visibility = visible
    return self
end

function Piece:setUV()
    for _, value in pairs(self.options.modelParts) do
        if not (self.options.texture or self.options.bounds) then break end -- Just stop
        if self.options.texture then
            value:setPrimaryTexture("CUSTOM", self.options.texture)
        end
        if self.options.bounds then
            value:setUVPixels(self.options.bounds.xy)
        end
    end
    return self
end

function Piece:__toggle()
    for _, event in ipairs(self.onToggle) do
        event(self.visibility)
    end
    return self
end

function Piece:equip()
    Logger.debug(self.name, "has been equipped")
    CURRENT_OUTFIT[self.id] = self
    self:setVisible(true):setUV()
    return self
end

function Piece:unequip()
    CURRENT_OUTFIT[self.id] = nil
    self:setVisible(false)
    return self
end

--#endregion Toast.Piece

--#region Toast.Outfit

config:setName("Toast.Piecewise")
config:save("version", "0.0.3")

---@class Toast.Outfit
local Outfit = {
    cache = config:load("saved") or {}
}

config:save("saved", Outfit.cache)

function Outfit.serialize(pieces)
    local buf = data:createBuffer(256)
    for _, piece in pairs(pieces) do
        Logger.debug("Deserializing", piece.id)
        piece:serialize(buf)
    end
    buf:setPosition(0)
    local output = buf:readByteArray()
    buf:close()
    return output
end

function Outfit.simplify()
    local output = {}
    for _, piece in pairs(CURRENT_OUTFIT) do
        output[#output + 1] = piece:simplify()
    end
    return output
end

function Outfit.deserialize(str)
    for _, modelPart in pairs(ALL_MODEL_PARTS) do
        modelPart:setVisible(false)
    end
    for _, piece in pairs(CURRENT_OUTFIT) do
        piece:unequip()
    end

    local buf = data:createBuffer(#str)
    buf:writeByteArray(str)
    buf:setPosition(0)

    for _ = 1, ALL_PIECES.count do --- Limit so we don't have an infinite loop, but still have a chance to read everything
        local piece = ALL_PIECES[buf:readInt()]
        if not piece then break end --- Reading was somehow corrupted, will wait until the next sync ping
        piece:deserialize(buf)
        if buf:available() <= 0 then break end
    end
    buf:close()
end

function pings.updateOutfit(serialized)
    if not host:isHost() then
        Outfit.deserialize(serialized) --- The host already ran the operations
    end
    local outfitView = Outfit.simplify()
    avatar:store("Piecewise.Current", outfitView)
end
function Outfit:save(name)
    self.cache[name] = self.serialize(CURRENT_OUTFIT) --- SHUT UP I KNOW WHAT'S IN THE TABLE
    config:setName("Toast.Outfits")
    config:save("saved", self.cache)
    return self.cache[name]
end

function Outfit:load(name)
    if not self.cache[name] then
        Logger.debug(("No outfit found with name '%s', ignoring"):format(name))
        return
    end
    pings.transfer(self.cache[name])
end

local timer = -20
local function scheduledPing()
    timer = timer + 1
    if timer % 80 == 0 then
        pings.transfer(Outfit.serialize(CURRENT_OUTFIT))
    end
end

events.TICK:register(scheduledPing, "scheduledPing")

--#endregion Toast.Outfit

return Piece, Outfit