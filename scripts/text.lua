-- text.lua
-- World Clocks drawn with Cairo and flags
-- by @wim66
-- v 0.7 May 16, 2025

require 'cairo'


-- Define a table containing information about different world clocks.
-- Each clock includes:
--   - label: The name of the city.
--   - zone: The time zone of the city.
--   - color: The color of the clock text in hexadecimal format.
--   - alpha: The transparency level (1.0 = fully opaque).
--   - flag: The path to the flag image associated with the city.
local world_clocks = {
    -- Top label has priority, doesn't scroll
    { label = "Amsterdam",    zone = "Europe/Amsterdam",                color = "#00D1FF", alpha = 1.0, flag = "images/NL.png" },
    { label = "Paris",        zone = "Europe/Paris",                    color = "#00FFEF", alpha = 1.0, flag = "images/FR.png" },
    { label = "London",       zone = "Europe/London",                   color = "#FFD300", alpha = 1.0, flag = "images/GB.png" },
    { label = "New York",     zone = "America/New_York",                color = "#FF4B00", alpha = 1.0, flag = "images/US.png" },
    { label = "Washington",   zone = "America/New_York",                color = "#00FF94", alpha = 1.0, flag = "images/US.png" },
    { label = "Las Vegas",    zone = "America/Los_Angeles",             color = "#FF1493", alpha = 1.0, flag = "images/US.png" },
    { label = "Suva",         zone = "Pacific/Fiji",                    color = "#a47de8", alpha = 1.0, flag = "images/FJ.png" },
    { label = "Wellington",   zone = "Pacific/Auckland",                color = "#4d94ff", alpha = 1.0, flag = "images/NZ.png" },
    { label = "Canberra",     zone = "Australia/Canberra",              color = "#00BFFF", alpha = 1.0, flag = "images/AU.png" },
    { label = "Tokyo",        zone = "Asia/Tokyo",                      color = "#FF006E", alpha = 1.0, flag = "images/JP.png" },
    { label = "Beijing",      zone = "Asia/Shanghai",                   color = "#7CFC00", alpha = 1.0, flag = "images/CN.png" },
    { label = "Jakarta",      zone = "Asia/Jakarta",                    color = "#CC0000", alpha = 1.0, flag = "images/ID.png" },
    { label = "Cape Town",    zone = "Africa/Johannesburg",             color = "#009900", alpha = 1.0, flag = "images/ZA.png" },
    { label = "Brasilia",     zone = "America/Sao_Paulo",               color = "#ff5782", alpha = 1.0, flag = "images/BR.png" },
    { label = "Buenos Aires", zone = "America/Argentina/Buenos_Aires",  color = "#FFAA00", alpha = 1.0, flag = "images/AR.png" },
}

-- Define settings for rendering text, headers, and labels
local settings = {
    scroll_speed = 4,                      -- Scroll speed in seconds
    font = "Ubuntu Mono",                  -- Font to use for text
    size = 14,                             -- Font size for the clock text
    header_size = 18,                      -- Font size for the header text
    header_x = 43,                         -- X-coordinate for the header text
    header_y = 35,                         -- Y-coordinate for the header text
    header_color = "#000000",              -- Color of the header text
    header_padding = 6,                    -- Padding around the header text
    header_corner_radius = 6,              -- Corner radius for the header background box
    header_border_width = 2,               -- Border width for the header box
    header_border_color = "#FFA726",       -- Border color for the header box
    header_gradient = {                    -- Gradient settings for the header background
        { offset = 0.0, color = "#FF0000" },   -- Start color (red)
        { offset = 0.5, color = "#FFFFFF" },   -- Middle color (white)
        { offset = 1.0, color = "#0000FF" }    -- End color (blue)
    },
    x = 46,                                -- X-coordinate for the clocks text
    y = 40,                                -- Y-coordinate for the first clock text
    line_height = 25,                      -- Line height between successive clocks
    flag_height = 16,                      -- Height of the flag images
    flag_x_offset = -30,                   -- Horizontal offset for flag images
    flag_y_offset = 12,                    -- Vertical offset for flag images
    label_bg_color = "#000000",            -- Background color for clock labels
    label_bg_alpha = 1,                    -- Background transparency for clock labels
    label_border_width = 2,                -- Border width for clock labels
    label_border_color = "#26A69A",        -- Border color for clock labels
    label_padding_x = 4,                   -- Horizontal padding inside clock labels
    label_padding_y = 1,                   -- Vertical padding inside clock labels
    label_corner_radius = 4                -- Corner radius for clock labels
}

-- Function: hex_to_rgb
-- Converts a hexadecimal color string to its RGB components
local function hex_to_rgb(hex)
    hex = hex:gsub("#", "") -- Remove the '#' character
    local r = tonumber(hex:sub(1, 2), 16) / 255 -- Extract red component
    local g = tonumber(hex:sub(3, 4), 16) / 255 -- Extract green component
    local b = tonumber(hex:sub(5, 6), 16) / 255 -- Extract blue component
    return { r = r, g = g, b = b } -- Return as a table
end

-- Function: set_rgba
-- Sets the RGBA color for Cairo operations
local function set_rgba(cr, hex, alpha)
    local rgb = hex_to_rgb(hex) -- Convert hex to RGB
    cairo_set_source_rgba(cr, rgb.r, rgb.g, rgb.b, alpha) -- Set RGBA color
end

-- Function: get_time
-- Executes a shell command to get the current time in a specific timezone
local function get_time(zone)
    local cmd = string.format("TZ='%s' date +%%H:%%M", zone) -- Command to get time
    local f = assert(io.popen(cmd), "Failed to run command") -- Run the command
    local time = f:read("*l") or "??:??:??" -- Read the output or fallback to "??:??:??"
    f:close() -- Close the command process
    return time -- Return the time as a string
end

-- Function: draw_rounded_rect
-- Draws a rectangle with rounded corners
local function draw_rounded_rect(cr, x, y, w, h, r)
    cairo_new_sub_path(cr)
    cairo_arc(cr, x + w - r, y + r, r, -math.pi / 2, 0) -- Top-right corner
    cairo_arc(cr, x + w - r, y + h - r, r, 0, math.pi / 2) -- Bottom-right corner
    cairo_arc(cr, x + r, y + h - r, r, math.pi / 2, math.pi) -- Bottom-left corner
    cairo_arc(cr, x + r, y + r, r, math.pi, 1.5 * math.pi) -- Top-left corner
    cairo_close_path(cr)
end

    -- Function to load and draw an image with a configurable height
local function draw_image(cr, path, x, y, height)
    -- Load the PNG image
    local image_surface = cairo_image_surface_create_from_png(path)
    
    -- Get the original width and height of the image
    local width = cairo_image_surface_get_width(image_surface)
    local original_height = cairo_image_surface_get_height(image_surface)
    
    -- Calculate the scaling factor based on the desired height
    local scale = height / original_height
    local new_width = width * scale -- Calculate the new width after scaling
    
    -- Ensure the new width does not exceed the maximum allowed width
    local max_width = 64 -- Maximum width for the scaled image (adjust as needed)
    if new_width > max_width then
        -- Recalculate the scale based on the maximum width
        scale = max_width / width
        new_width = max_width
        height = original_height * scale -- Adjust the height proportionally
    end
    
    -- Apply the scaling transformation
    cairo_save(cr) -- Save the current state of the Cairo context
    cairo_translate(cr, x, y) -- Translate the context to the specified (x, y) position
    cairo_scale(cr, scale, scale) -- Scale the context by the calculated factor
    
    -- Draw the image on the scaled context
    cairo_set_source_surface(cr, image_surface, 0, 0) -- Set the image as the source
    cairo_paint(cr) -- Paint the image onto the context
    
    -- Restore the original transformation matrix
    cairo_restore(cr)
    
    -- Clean up the image surface to free memory
    cairo_surface_destroy(image_surface)
end

local start_time = os.time()

local function get_scroll_offset()
    local current_time = os.time() + (os.clock() % 1)
    local elapsed_time = current_time - start_time
    local offset = (elapsed_time / settings.scroll_speed) % (#world_clocks - 1)
    return offset
end

    -- Function: conky_draw_text
    -- Main function to draw the world clock text and flags
    function conky_draw_text()
    if conky_window == nil then return end -- Exit if Conky window is not available

    -- Create a Cairo surface and context for drawing
    local cs = cairo_xlib_surface_create(
        conky_window.display,
        conky_window.drawable,
        conky_window.visual,
        conky_window.width,
        conky_window.height
    )
    local cr = cairo_create(cs)

    -- Prepare header text
    local header_text = "World Clocks" -- Header text (in English)
    cairo_select_font_face(cr, settings.font, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
    cairo_set_font_size(cr, settings.header_size)
    local ext = cairo_text_extents_t:create()
    cairo_text_extents(cr, header_text, ext)

    -- Calculate header box dimensions based on text extents
    local x = settings.header_x
    local y = settings.header_y
    local pad = settings.header_padding
    local box_x = x + ext.x_bearing - pad
    local box_y = y + ext.y_bearing - pad
    local box_w = ext.width + 2 * pad
    local box_h = ext.height + 2 * pad

    -- Draw header background gradient
    local grad = cairo_pattern_create_linear(box_x, box_y, box_x, box_y + box_h)
    for _, stop in ipairs(settings.header_gradient) do
        local rgb = hex_to_rgb(stop.color)
        cairo_pattern_add_color_stop_rgba(grad, stop.offset, rgb.r, rgb.g, rgb.b, 1.0)
    end
    draw_rounded_rect(cr, box_x, box_y, box_w, box_h, settings.header_corner_radius)
    cairo_set_source(cr, grad)
    cairo_fill_preserve(cr)

    -- Draw header border
    set_rgba(cr, settings.header_border_color, 1.0)
    cairo_set_line_width(cr, settings.header_border_width)
    cairo_stroke(cr)

    -- Draw header text
    set_rgba(cr, settings.header_color, 1.0)
    cairo_move_to(cr, x, y)
    cairo_show_text(cr, header_text)

    -- Draw each clock entry
    cairo_set_font_size(cr, settings.size)

    -- Draw priority label (always at the top)
    local priority_city = world_clocks[1]
    local time = get_time(priority_city.zone)
    local y = settings.y + settings.line_height
    local label_text = string.format("%-14s %s", priority_city.label .. ":", time)

    local extents = cairo_text_extents_t:create()
    cairo_text_extents(cr, label_text, extents)
    local text_width = extents.width
    local bg_x = settings.x + settings.flag_x_offset - settings.label_padding_x
    local bg_y = y - settings.flag_y_offset - settings.label_padding_y
    local bg_w = settings.flag_height + (-settings.flag_x_offset) + text_width - 15 + settings.label_padding_x * 2
    local bg_h = settings.flag_height + settings.label_padding_y * 2

    -- Label background
    set_rgba(cr, settings.label_bg_color, settings.label_bg_alpha)
    draw_rounded_rect(cr, bg_x, bg_y, bg_w, bg_h, settings.label_corner_radius)
    cairo_fill_preserve(cr)

    -- Border
    set_rgba(cr, settings.label_border_color, 1.0)
    cairo_set_line_width(cr, settings.label_border_width)
    cairo_stroke(cr)

    -- Flag
    local flag_x = settings.x + settings.flag_x_offset
    draw_image(cr, priority_city.flag, flag_x, y - settings.flag_y_offset, settings.flag_height)

    -- Text
    set_rgba(cr, priority_city.color, priority_city.alpha)
    cairo_move_to(cr, settings.x, y)
    cairo_show_text(cr, label_text)

    -- Draw the remaining cities with scrolling, starting from index 2
        local visible_lines = 9  -- Number of cities displayed alongside the priority clock
        local offset = get_scroll_offset()
        for i = 1, visible_lines do
        local index = math.floor(#world_clocks - 1 - (offset + i - 1)) % (#world_clocks - 1) + 2  -- +2 to start from the second item
        local city = world_clocks[index]
        local time = get_time(city.zone)
        local y = settings.y + (visible_lines - i + 1) * settings.line_height  -- +1 to start below Amsterdam
        local label_text = string.format("%-14s %s", city.label .. ":", time)

        local extents = cairo_text_extents_t:create()
        cairo_text_extents(cr, label_text, extents)
        local text_width = extents.width
        local bg_x = settings.x + settings.flag_x_offset - settings.label_padding_x
        local bg_y = y - settings.flag_y_offset - settings.label_padding_y
        local bg_w = settings.flag_height + (-settings.flag_x_offset) + text_width - 15 + settings.label_padding_x * 2
        local bg_h = settings.flag_height + settings.label_padding_y * 2

        -- Label background
        set_rgba(cr, settings.label_bg_color, settings.label_bg_alpha)
        draw_rounded_rect(cr, bg_x, bg_y, bg_w, bg_h, settings.label_corner_radius)
        cairo_fill_preserve(cr)

        -- Border
        set_rgba(cr, settings.label_border_color, 1.0)
        cairo_set_line_width(cr, settings.label_border_width)
        cairo_stroke(cr)

        -- Flag
        local flag_x = settings.x + settings.flag_x_offset
        draw_image(cr, city.flag, flag_x, y - settings.flag_y_offset, settings.flag_height)

        -- Text
        set_rgba(cr, city.color, city.alpha)
        cairo_move_to(cr, settings.x, y)
        cairo_show_text(cr, label_text)
    end

    -- Clean up the Cairo context and surface
    cairo_destroy(cr)
    cairo_surface_destroy(cs)
end