if not host:isHost() then return end

local Piece = require("./piece") ---@type Toast.Piece

local page = action_wheel:newPage("Outfits")
local categories = {} ---@type Page[]
local PART_TYPES = {
    HAT = "Hats",
    BODY_BASE = "Body Bases",
    BODY_LAYER = "Body Layers",
    LEFT_HAND = "Left Hand Accessories",
    RIGHT_HAND = "Right Hand Accessories",
    PANTS = "Pants",
    SHOES = "Shoes",
    OUTFIT = "Loaded Outfits",
} ---@type table<Toast.Part.Type, string>

local foundColors = {}

local colorsPage = action_wheel:newPage("Toast.Colors")

for partName, title in pairs(PART_TYPES) do
    categories[partName] = action_wheel:newPage(partName)
    page:newAction()
        :setTitle(title)
        :setOnLeftClick(
            function()
                action_wheel:setPage(categories[partName])
            end
        )
end

local function addColors(palette)
    foundColors[palette[1]] = palette
end

for id, piece in pairs(Piece.ALL) do ---@cast piece Toast.Piece.Type
    if not piece.options then return end
    local partType = piece.options.part
    if not partType then return end
    categories[partType]:newAction()
        :onToggle(function(state, self)
            if state then
                piece:equip()
            else
                piece:unequip()
            end

            if piece.type == "Tintable" then
                ---@cast piece Toast.TintablePiece
                if piece.options.palette then
                    addColors(piece.options.palette)
                end
                updateColorsPage(piece)
                action_wheel:setPage(colorsPage)
            end
        end
        )
end
