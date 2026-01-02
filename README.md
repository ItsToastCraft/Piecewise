--
This is essentially a piece / outfit manager library idk what other people do...

# Pieces
> It just holds model parts together and toggles them all at once

Pieces can manage UVs and textures, allowing outfit pieces to be reusable as long as they all share the same UV form.
Synced to others every 5 seconds.

# Tintables
<sub>My favorite!</sub>

Adds the ability for pieces to be tinted, with 3 methods\
Seperate module, so it's optional; Pieces will still work without it! 

* SIMPLE - will just call :setColor() on all model parts
* PALETTE - will use a palette defined in the part's settings and an index
* RGB - will create a palette from an RGB value and apply it

<sub>Will be improved to use new Texture methods in 0.1.6</sub>\
<sub>moved INDEXED mode because it's just PALETTE with extra steps</sub>

# Outfit
Outfits can be saved using ``Outfit:save(name)``, and read back using ``Outfit:load(name)``
> [!NOTE]
> The pieces used to make that outfit must stay created!

# How to Use

Creating a piece
```lua
local Piece = require("piece")
local hat = Piece:new("Hat", {part = "HAT", modelParts = models.model.Hat}) -- options, modelParts is mandatory
```

Equipping a piece
```lua
hat:equip() -- So shrimple
```

Creating a piece using another as a base
```lua
local Piece = require("piece")
local shirt = Piece:new("Shirt", {
  part = "BODY_LAYER", -- Not used rn but was used in v2 and might be brought back
  modelParts = {models.model.SweaterMain}, 
  texture = textures["model.main"], -- The texture the part uses
  bounds = vec(0, 0, 38, 45) -- The region of the texture the whole piece occupies PLEASE CLUMP THE MODEL PART UVs TOGETHER
})
--- Sweater will automatically shift UVs and change the texture of `shirt`'s modelParts when equipped.
local sweater = shirt:copy("Sweater", {
  bounds = vec(38, 0, 38, 45)
}) 
```

## Tintables
Creating a Tintable
```lua
local Tintable, Recolor = require("tintable")
local baseballCap = Tintable:new("Baseball Cap",{
  tintMethod = "COLOR",
  texture = textures["model.hats"],
  bounds = vec(0, 0, 32, 32),
  modelParts = { models.model.Hat }
})

-- Recolors the hat with a random color and a red accent
baseballCap:setColor(Recolor.randomColor(), 0x973131):equip() -- setColor takes 2 params, one for primary layer and one for secondary
```

Creating a Palette mode Tintable
```lua
local Tintable = require("tintable")
local jeans = Tintable:new("jeans",
    {
        modelParts = { models.model.Pants },
        part = "PANTS",
        texture = textures["model.pants"],
        tintMethod = "PALETTE",
        bounds = vec(0, 0, 36, 24),
        palette = {
            { "2d3959", "242c4d", "1b213d", "12142c" },
            { "5482b8", "4d73aa", "416095", "3a5483" },
            { "80a4c5", "698bb1", "5b77a2", "4d618e" },
            { "b8d4e9", "a2bed7", "859dc1", "7b8db3" },
        },
    })

jeans:setColor(math.random(4)):equip()
```
