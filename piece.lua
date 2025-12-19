local utils = require("utils")

local nextAvailable = 0
local AllParts = { {}, {}, {}, {}, {}, {}, {}, {} }
local ModelPartList = {}

---@enum Toast.Part
local PartTypes = {
    HAT = 1,
    BODY_BASE = 2,
    BODY_LAYER = 3,
    LEFT_HAND = 4,
    RIGHT_HAND = 5,
    PANTS = 6,
    SHOES = 7,
    MULTIPART = 8,
}
local EMPTY_VECTOR = vec(0, 0, 0)  -- Empty vector
local BODY_OFFSET = vec(0, -12, 0) -- Default offset for body parts

---@type table<Toast.Part, Vector3> The default offsets for each part type. This is used to determine the offset for the skull position.
local defaultOffsets = {
    vec(0, -24, 0), BODY_OFFSET, BODY_OFFSET,
    BODY_OFFSET, BODY_OFFSET, EMPTY_VECTOR, EMPTY_VECTOR,
}

--#region ToastTextures.Piece

---@class Toast.Piece
local Piece = {
    __type = "Piece",
}

-- function Piece.copyOf(name, instance, options)
--     options = options or instance.options or {}
--     instance = setmetatable(utils.deepCopy(instance), Piece)
-- end

function Piece.new(name, options)
    options = options or {}
    local self = setmetatable({}, { __index = Piece })
    self.name = name
    self.index = nextAvailable
    options.skullOffset = options.skullOffset or defaultOffsets[options.part]

    nextAvailable = nextAvailable + 1
    table.insert(AllParts[options.part], self)
    return self
end

function Piece:serialize()
    return tostring(self.index)
end

function Piece:deserialize()
end

local a = Piece.new("hello", { part = PartTypes.HAT, modelParts = { models.model } })

a:deserialize()


--#endregion


--#region Toast.Networking

function pings.updateClothing() end


--#endregion

