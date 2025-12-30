---@meta _

---Part type that the piece is a part of
---@alias Toast.Part.Type
---| "HAT"
---| "BODY_BASE"
---| "BODY_LAYER"
---| "LEFT_HAND"
---| "RIGHT_HAND"
---| "PANTS"
---| "SHOES"
---| "MULTIPART"

---@class Toast.Piece
---@field options Toast.Piece.Options
---@field id integer
---@field serialize Toast.Serializer
---@field deserialize Toast.Deserializer<Toast.Piece>
local Piece


---Loads all of the model parts into a table so that they can all be toggled
---when an outfit is read from the update ping.
---@param parts ModelPart[]
function Piece:updateModelParts(parts) end

---Creates a new piece.
---@generic T: Toast.Piece.Type
---@generic O: Toast.Piece.Options
---@param self T
---@param name string
---@param options O
---@return T
function Piece.new(self, name, options) end

---Creates a copy of a piece

---@generic T: Toast.Piece.Type
---@generic O: Toast.Piece.Options
---@param self T --- An instance of any Piece
---@param name string The name of the new Piece
---@param options O --- Piece options
---@return T
function Piece.copy(self, name, options) end

---Adds a piece to be equipped
---@generic T: Toast.Piece.Type
---@param self T --- An instance of any Piece
function Piece.equip(self) end

---@class (exact) Toast.Piece.Options
---@field bounds Vector4? The area of the texture. Only used if you're messing with the UVs, especially if the piece's texture is a part of a larger texture.
---@field skullOffset Vector3? The offset for the skull position (used for action wheel). If not provided, it will be set based on the part type.
---@field part Toast.Part.Type? The part type. This is used to determine what category to put it under.
---@field texture Texture? The texture file to use for the piece. Useful if you're setting the UV because there are multiple pieces with the same model parts. Uses the `bounds` option.
---@field modelParts ModelPart[] The model parts to use for the piece. This is used to determine what parts to toggle.

---@class Toast.TintablePiece: Toast.Piece
---@field options Toast.Tintable.Options
---@field serialize Toast.Serializer
---@field deserialize Toast.Deserializer<Toast.TintablePiece>
---@field tint Toast.TintablePiece.Method

---@class Toast.Tintable.Options : Toast.Piece.Options
---@field tintMethod Toast.TintablePiece.Mode
---@field palette table? The palette to use for tinting. This is only used if the tintType is "palette".
---@field primary integer? The color applied to the part. Color is either a valid color type or an RGB value converted into an integer.
---@field secondary integer? The color applied to the part. Color is either a valid color type or an RGB value converted into an integer.


---@alias Toast.Multipiece Toast.Piece.Type[]

---@alias Toast.TintablePiece.Method fun(piece: Toast.TintablePiece, value: RGB, layer: Toast.Layer?)

---Modes used for tinting.
---@alias Toast.TintablePiece.Mode
---| "SIMPLE" Uses simple (:setColor()) method for recoloring
---| "RGB" Uses an RGB value given by the user.
---| "INDEXED" Uses a premade 16 color palette.
---| "PALETTE" Uses a custom palette. The piece __must__ have `palette` defined in its options.


---@alias Toast.Serializer fun(self: self, buf: Buffer)
---@alias Toast.Deserializer<T> fun(self: self?, data: Buffer): T

---@alias Toast.Piece.Type
---| Toast.Piece
---| Toast.TintablePiece

---@alias Toast.Colorable.TextureModifier fun(color: RGB, texture: Texture, bounds: Vector4, layer: Toast.Layer)
