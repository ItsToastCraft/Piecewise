---@meta _ 

---@alias Toast.Recolor.Palette table<Vector4, integer> | Vector4[]

---@alias Toast.Recolor.RemapMode
---| "RGB"
---| "HEX"
---| "INT"

---@alias Toast.Recolor.Remappable
---| Vector3
---| string
---| integer

---@class Toast.Recolor
local Recolor

---Remaps a value representing a color to another.
---@param value Toast.Recolor.Remappable
---@param mode Toast.Recolor.RemapMode
---@return Toast.Recolor.Remappable
function Recolor.remapTo(value, mode) end

---@private
---@param value Toast.Recolor.Remappable
---@param buf Buffer
function Recolor.serializeColor(value, buf) end

---Converts a serialized color to its RGB representation.
---@param buf Buffer
---@return Vector3
function Recolor.deserializeColor(buf) end

---Generates a 5 color palette from an input.
---@param input Toast.Recolor.Remappable
---@return Toast.Recolor.Palette
function Recolor.generatePalette(input) end

---Generates a random RGB color.
---@return Vector3
function Recolor.randomColor() end

---Util function that converts user format to RGB.
---@param palette Toast.Recolor.Palette
---@return Toast.Recolor.Palette
function Recolor.mapPaletteToRGB(palette) end

---Splits a texture into seperate pieces, and runs operations on different ticks, in order to not overrun instructions.
---
---! NOTE: This will be removed in 0.1.6, due to better Texture manipulation methods !
---@param tex Texture
---@param bounds Vector4
---@param func Texture.applyFunc
function Recolor.splitTexture(tex, bounds, func) end