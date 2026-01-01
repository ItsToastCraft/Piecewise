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

---@class Toast.Piece
---@field options Toast.Piece.Options
---@field id integer
---@field serialize Toast.Serializer
---@field deserialize Toast.Deserializer<Toast.Piece>
local Piece

---Loads all of the model parts into a table so that they can all be toggled
---when an outfit is read from the update ping.
---@generic T
---@param self T
---@param parts ModelPart[]
---@return T
function Piece:updateModelParts(parts) end

---Creates a new piece.
---@generic T: Toast.Piece.Type
---@generic O: Toast.Piece.Options
---@param self T
---@param name string
---@param options O
---@return self
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
---@field updateModelParts fun(self: self): self
---@field options Toast.Tintable.Options
---@field serialize Toast.Serializer
---@field deserialize Toast.Deserializer<Toast.TintablePiece>
---@field tint Toast.TintablePiece.Method
local Tintable

---@class Toast.Tintable.Options : Toast.Piece.Options
---@field tintMethod Toast.TintablePiece.Mode
---@field palette Toast.Palette[]? The palette to use for tinting. This is only used if the tintType is "palette".
---@field primary integer? The color applied to the part. Color is either a valid color type or an RGB value converted into an integer.
---@field secondary integer? The color applied to the part. Color is either a valid color type or an RGB value converted into an integer.

---Resets the piece's UV and texture, so that those elements can be reused.
function Tintable:reset() end

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

---@alias Toast.Outfit.Parser fun(self: self, name: string)


---@alias Toast.Piece.Type
---| Toast.Piece
---| Toast.TintablePiece

---@alias Toast.Layer
---| "PRIMARY"
---| "SECONDARY"

---@alias RGB Vector3 idk

---A list of colors indexed by their hex value.
---@alias Toast.Palette table<string, integer> | RGB[]

---@alias Toast.Colorable.TextureModifier fun(color: RGB, texture: Texture, bounds: Vector4, layer: Toast.Layer)

---Literally just transfers the data to another client that's their problem now
---
---@param data string
---@see Toast.Deserializer
function pings.transfer(data) end

--#region Toast.Recolor

---@class Toast.Recolor
local Recolor

---Converts a color to 3 bytes and adds them to the buffer to be pinged.
---@param hex RGB|integer
---@param buf Buffer
function Recolor.serializeColor(hex, buf) end

---Deserializes the color from the buffer
---@param buf Buffer
---@return RGB
function Recolor.deserializeColor(buf) end

---Generates a random color.
---@return RGB
function Recolor.randomColor() end

---Splits a texture into quadrants so that it doesn't eat tick instructions (deprecated in 0.1.6)
---@param tex Texture
---@param bounds Vector4
---@param func Texture.applyFunc
function Recolor.splitTexture(tex, bounds, func) end

---Generates a palette from a starting color.
---
--- ! EXPERIMENTAL ! - I still need to tweak the values,
--- and the colors produced are highly stylized to look like mine, so tweak this yourself for different results!
---@param input RGB
---@return Toast.Palette
function Recolor.generatePalette(input) end

--#endregion Toast.Recolor
