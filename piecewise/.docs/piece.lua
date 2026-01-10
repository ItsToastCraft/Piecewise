---@meta _

---@alias Toast.Part
---| "HAT"
---| "BODY_MAIN"
---| "BODY_LAYER"
---| "LEFT_HAND"
---| "RIGHT_HAND"
---| "PANTS"
---| "SHOES"
---| "OUTFIT"

---@alias Toast.ToggleEvent fun(state: boolean)

--- Codec
---@alias Toast.Serializer fun(self: self, buf: Buffer)
---@alias Toast.Deserializer fun(self: self?, data: Buffer): self

---@class (exact) Toast.Piece.Options
---@field bounds Vector4? The area of the texture. Only used if you're messing with the UVs, especially if the piece's texture is a part of a larger texture.
---@field skullOffset Vector3? The offset for the skull position (used for action wheel). If not provided, it will be set based on the part type.
---@field part Toast.Part? The part type. This is used to determine what category to put it under.
---@field texture Texture? The texture file to use for the piece. Useful if you're setting the UV because there are multiple pieces with the same model parts. Uses the `bounds` option.
---@field modelParts ModelPart[] The model parts to use for the piece. This is used to determine what parts to toggle.

---@class Toast.Piece The basic piece type. Supports UV remapping and texture swapping.
---@field __index Toast.Piece
---@field name string The name of the piece.
---@field id integer The internal identifier used for the piece.
---@field visibility boolean The current visibility of the piece.
---@field options Toast.Piece.Options Any options set to the piece.
---@field onToggle Toast.ToggleEvent[] A list of functions that are triggered when a piece is enabled / disabled.
local Piece

---Creates a new instance of a piece.
---@param name string The name of the new piece.
---@param options Toast.Piece.Options The options given to the Piece
---@return self
function Piece:new(name, options) end

---Creates a simplified view of a piece that is shared with others.
---Can be used to match outfits or match colors.
---
---Removes any variables that can be modified.
---@return table
function Piece:simplify()
end

---Creates a copy of a piece, using the original piece as defaults.
---@param name string The name of the new piece.
---@param options Toast.Piece.Options The options given to the Piece
---@return self
function Piece:copy(name, options) end

---Sets the visibility of a piece.
---@param visible boolean
---@return self
function Piece:setVisible(visible) end

---Registers a new function that is triggered when that piece is enabled / disabled.
---@param fun Toast.ToggleEvent
function Piece:registerToggle(fun) end

---Converts a piece's data to a string.
---
---! THIS WILL RARELY BE CALLED BY THE USER; ONLY USE IF YOU KNOW WHAT YOU'RE DOING !
---@param buf Buffer
function Piece:serialize(buf) end

---Reads from a buffer and locates the right piece.
---
---! THIS WILL RARELY BE CALLED BY THE USER; ONLY USE IF YOU KNOW WHAT YOU'RE DOING !
---@param buf Buffer Not actually used currently by the function but still...
---@return self
function Piece:deserialize(buf) end

---Updates all of the model parts and adds them to a collection of parts
---so they're not read multiple times.
---@param parts ModelPart[]
---@return self 
function Piece:updateModelParts(parts) end

---Modifies the UVs of the model parts (allows for model parts to belong to multiple pieces)
---@return self
function Piece:setUV() end

---Runs all of the registered functions when toggled.
---
---! THIS IS NOT MEANT TO BE CONFUSED WITH `Piece:equip() / Piece:unequip()` !
---@see Piece:equip for showing a piece
---@see Piece:unequip for hiding a piece
---@return self
function Piece:__toggle() end

---Equips a piece.
---@return self
function Piece:equip()

---Unequips a piece.
---@return self
function Piece:unequip()

---@class Toast.Outfit
local Outfit

---Serializes a set of pieces.
---@generic T: Toast.Piece
---@param pieces T[]
---@return string
function Outfit.serialize(pieces) end

---Converts a string into the respective pieces.
---@param str string
function Outfit.deserialize(str) end

---Simplifies all current pieces and collects them in a table.
function Outfit.simplify() end

---Updates the outfit on other player's accounts.
---@param serialized string
function pings.updateOutfit(serialized) end