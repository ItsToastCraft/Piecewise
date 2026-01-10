local Tintable = require("piecewise.tintable")
local Recolor = require("piecewise.recolor")
vanilla_model.PLAYER:setVisible(false)
local outfitModel = models.model.Outfit

local sweaterBase = Tintable:new("sweater",
    {
        texture = textures.sweaters,
        primary = 1,
        tintMethod = "COLOR",
        bounds = vec(0, 0, 38, 45),
        part = "BODY_LAYER",
        details = "low",
        modelParts = { outfitModel.bodyLayer },
    })
local sweaterOpen = sweaterBase:copy("open", { bounds = vec(0, 48, 38, 45) })
local jeans = Tintable:new("jeans",
    {
        modelParts = { outfitModel.pants },
        part = "PANTS",
        texture = textures.pants,
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

local timer = -30
local toggle = false
if not host:isHost() then return end
function events.TICK()
    timer = timer + 1
    if timer % 60 == 0 then
        toggle = not toggle
        if toggle then
            sweaterBase:unequip()
            sweaterOpen:setColor(Recolor.randomColor(), Recolor.randomColor()):equip()
        else
            sweaterOpen:unequip()
            sweaterBase:setColor(Recolor.randomColor()):equip()
        end
    end
end
