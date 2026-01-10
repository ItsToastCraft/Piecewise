---@meta _

---@class Toast.Tintable.Options : Toast.Piece.Options
---@field tintMethod Toast.Tintable.Mode
---@field palette Toast.Palette[]? The palette to use for tinting. This is only used if the tintType is "palette".
---@field primary integer? The color applied to the part. Color is either a valid color type or an RGB value converted into an integer.
---@field secondary integer? The color applied to the part. Color is either a valid color type or an RGB value converted into an integer.

---@class (partial) Toast.Tintable: Toast.Piece
---@field tint Toast.Tintable.Func
---@field options Toast.Tintable.Options
local Tintable

---@alias Toast.Layer
---| "PRIMARY"
---| "SECONDARY"

---I have to redefine for the Tintable options override smh

---Creates a new instance of a piece
---@param name string The name of the new piece.
---@param options Toast.Tintable.Options 
---@return self
function Tintable:new() end

---Creates a copy of a piece, using the original piece as defaults
---@param name string The name of the new piece.
---@param options Toast.Tintable.Options The options given to the Piece
---@return self
function Tintable:copy(name, options) end

---@alias Toast.RGB Vector3

---@alias Toast.Tintable.Func fun(piece: Toast.Tintable, value: integer | Toast.Recolor.Remappable, layer: Toast.Layer?)

---@class Toast.Tintable.BuiltinFuncs
local funcs

---@alias Toast.Tintable.Mode
---| "SIMPLE"
---| "COLOR"
---| "PALETTE"

---Simply applies :setColor() to every modelPart.
---
---! NOTE: This mode cannot support layers, as it applies the same color to all pixels !
---@param piece Toast.Tintable
---@param value integer
function funcs.SIMPLE(piece, value) end

---Remaps all of the colors to a dynamically generated palette from a single value.
---@param piece Toast.Tintable
---@param value Toast.Recolor.Remappable
---@param layer Toast.Layer
function funcs.COLOR(piece, value, layer) end

---Remaps all of the colors to a premade palette using the index of the palette.
---@param piece Toast.Tintable
---@param index integer
---@param layer Toast.Layer
function funcs.PALETTE(piece, index, layer) end