-- loadall.lua
-- World Clocks drawn with Cairo and flags
-- by @wim66
-- v 0.6 May 15, 2025

-- Set the path to the scripts folder
package.path = "./scripts/?.lua"
-- ###################################


require 'background'
require 'globe'
require 'text'

function conky_main()
    if conky_window == nil then
        return
    end
    conky_draw_background()
    conky_draw_globe()
    conky_draw_text()
end
