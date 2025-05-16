-- layout.lua
-- Defines the box-layout for layer2 and border
-- by @wim66
-- v 0.7 May 15, 2025

local M = {}

-- === Colour-parsers ===
local function parse_color_gradient(str, default)
    local gradient = {}
    for position, color, alpha in str:gmatch("([%d%.]+),0x(%x+),([%d%.]+)") do
        table.insert(gradient, {tonumber(position), tonumber(color, 16), tonumber(alpha)})
    end
    return #gradient == 3 and gradient or default
end
local colours = require "border_colour_schemes"

-- == Colours to choose from == --
-- colours.wim66_green          💚
-- colours.crimson_flame        🔴
-- colours.ocean_deep           🔵
-- colours.emerald_glow         🟢
-- colours.mystic_twilight      🌌
-- colours.solar_ember          🟠
-- colours.aurora_borealis      ✨
-- colours.sunset_blaze         🌟
-- colours.forest_frenzy        🌿
-- colours.frozen_tundra        ❄️
-- colours.inferno              🔥
-- colours.rainbow              🌈

-- === Border Colour ===
local my_box_colour = colours.ocean_deep

-- === Layout ===
M.boxes_settings = {
    {
        type = "image",
        x = 0, y = 6, w = 455, h = 298,
        centre_x = true,
        rotation = 0,
        draw_me = true,
        image_path = "images/earth2.png"
        
    },
    {
        type = "background",
        x = 0, y = 0, w = 468, h = 308,
        centre_x = true,
        corners = { 20, 20, 20, 20 },
        rotation = 0,
        draw_me = false,
        colour = { { 1, 0x1d1d2e, 0.4 } }
    },
    
    {
        type = "border",
        x = 0, y = 0, w = 470, h = 310,
        centre_x = true,
        corners = { 20, 20, 20, 20 },
        rotation = 0,
        draw_me = true,
        border = 8,
        colour = my_box_colour,
        linear_gradient = { 0, 0, 470, 0 }
    },
}

return M
