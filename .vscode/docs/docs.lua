---@meta

---@class Toast.Serializeable
local Serializeable

---@private
---@return string Serialized data
function Serializeable:serialize() end

---@private
---@generic T: Toast.Serializeable
---@param self T
---@param data string
---@return T A reconstructed object
function Serializeable.deserialize(self, data) end

---A piece!
---@class Toast.Piece: Toast.Serializeable
---@field index number The piece index, used for serialization
---@field name string
---@field __type table
---@field options Toast.PieceOptions
local Piece

---@class Toast.PieceOptions
---@field part Toast.Part
---@field texture Texture?
---@field textureBounds Vector4?
---@field skullOffset Vector3?
---@field detailLevel number?
---@field modelParts ModelPart[]

---Creates a new piece.
---@param name string
---@param options Toast.PieceOptions
---@return Toast.Piece
function Piece.new(name, options) end

---@class Toast.TintablePiece: Toast.Piece

---@class Toast.MultipartPiece: Toast.Piece
