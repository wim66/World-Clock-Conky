-- globe.lua
-- World Clocks drawn with Cairo and flags
-- by @wim66
-- v 0.7 May 16, 2025

-- Load Cairo libraries for drawing functionality
local cairo = require('cairo')
local status, cairo_xlib = pcall(require, 'cairo_xlib')
if not status then
    -- Fallback for environments without cairo_xlib
    cairo_xlib = setmetatable({}, { __index = function(_, key) return _G[key] end })
end

-- Configuration settings for the globe and its elements
local config = {
    rotation_speed = 30,              -- Speed for a full globe rotation, lower is faster
    pin_length = 20,                  -- Default length of the pin line from the globe to the label
    pin_radius = 5,                   -- Radius of the city pinhead (circle)
    font_name = "Ubuntu Mono",        -- Font used for city labels
    font_size = 12,                   -- Font size for labels
    label_color_hex = "#000000",      -- Default text color for labels (black)
    label_offset = 14,                -- Distance in pixels between the pin-head and label
    xc = 340,                         -- X-coordinate for the center of the globe
    yc = 160,                         -- Y-coordinate for the center of the globe
    radius = 90,
    globe_alpha = 0.75,
    globe_shadow = 0.2,                     -- Radius of the globe
    tilt = 23.5 * math.pi / 180       -- Earth's axial tilt in radians
}

-- Directory containing flag images
local flag_dir = "images/"

-- Mapping of city names to their corresponding flag image files
local flags = {
    ["Amsterdam"] = "NL.png",
    ["New York"] = "US.png",
    ["Tokyo"] = "JP.png",
    ["London"] = "GB.png",
    ["Moscow"] = "RU.png",
    ["Beijing"] = "CN.png",
    ["Brasilia"] = "BR.png",
    ["Canberra"] = "AU.png",
    ["Paris"] = "FR.png",
    ["Washington D.C."] = "US.png",
    ["Las Vegas"] = "US.png",
    ["Buenos Aires"] = "AR.png",
    ["Cape Town"] = "ZA.png",
    ["Wellington"] = "NZ.png",
    ["Jakarta"] = "ID.png",
    ["Suva"] = "FJ.png",
}

-- Function to project 3D globe coordinates to 2D screen coordinates
local function project(lat, lon)
    -- Convert latitude and longitude into 3D Cartesian coordinates
    local x = math.cos(lat) * math.sin(lon)
    local y = math.sin(lat)
    local z = math.cos(lat) * math.cos(lon)

    -- Apply Earth's axial tilt to the y and z coordinates
    local y_tilt = y * math.cos(config.tilt) - z * math.sin(config.tilt)
    local z_tilt = y * math.sin(config.tilt) + z * math.cos(config.tilt)

    return x, y_tilt, z_tilt
end

-- Function to convert hexadecimal color values to RGB
local function hex_to_rgb(hex)
    hex = hex:gsub("#", "") -- Remove the '#' character
    local r = tonumber(hex:sub(1, 2), 16) / 255 -- Extract red component
    local g = tonumber(hex:sub(3, 4), 16) / 255 -- Extract green component
    local b = tonumber(hex:sub(5, 6), 16) / 255 -- Extract blue component
    return { r = r, g = g, b = b } -- Return as a table
end

-- Function to draw rectangles with rounded corners
local function rounded_rectangle(cr, x, y, w, h, r)
    cairo_new_sub_path(cr)
    cairo_arc(cr, x + w - r, y + r, r, -math.pi / 2, 0)           -- Top-right corner
    cairo_arc(cr, x + w - r, y + h - r, r, 0, math.pi / 2)        -- Bottom-right corner
    cairo_arc(cr, x + r, y + h - r, r, math.pi / 2, math.pi)      -- Bottom-left corner
    cairo_arc(cr, x + r, y + r, r, math.pi, 3 * math.pi / 2)      -- Top-left corner
    cairo_close_path(cr)
end

-- Function to calculate rotation based on current time
local start_time = os.time()
local function get_rotation()
    local now = os.clock()
    local rotation = (now - start_time) * 2 * math.pi / config.rotation_speed
    return rotation
end

-- Function to draw the globe
local function draw_globe(cr)
    -- Draw a shadow behind the globe
    cairo_set_source_rgba(cr, 0, 0, 0, config.globe_shadow) -- Shadow color with transparency
    cairo_arc(cr, config.xc + 3, config.yc + 3, config.radius, 0, 2 * math.pi)
    cairo_fill(cr)

    -- Determine the current rotation angle of the globe
    local rotation = get_rotation()

    -- Draw the globe
    cairo_set_source_rgba(cr, 0, 0.5, 1, config.globe_alpha)
    cairo_arc(cr, config.xc, config.yc, config.radius, 0, 2 * math.pi)
    cairo_fill(cr)

    -- Draw longitude and latitude lines
    cairo_set_source_rgba(cr, 1, 1, 1, 0.2) -- White color with transparency
    cairo_set_line_width(cr, 1)

    -- Draw longitude lines
    for lon = -180, 150, 30 do
        local theta = (lon * math.pi / 180) + rotation -- Convert to radians
        cairo_new_path(cr)
        for phi = -90, 85, 5 do
            local phi1 = phi * math.pi / 180
            local phi2 = (phi + 5) * math.pi / 180
            local x1, y1, z1 = project(phi1, theta)
            local x2, y2, z2 = project(phi2, theta)
            if z1 > 0 and z2 > 0 then -- Only draw visible parts
                cairo_move_to(cr, config.xc + config.radius * x1, config.yc - config.radius * y1)
                cairo_line_to(cr, config.xc + config.radius * x2, config.yc - config.radius * y2)
            end
        end
        cairo_stroke(cr)
    end

    -- Draw latitude lines
    for lat = -75, 75, 15 do
        local phi = lat * math.pi / 180 -- Convert to radians
        cairo_new_path(cr)
        for theta = 0, 2 * math.pi, 0.1 do
            local x1, y1, z1 = project(phi, theta + rotation)
            local x2, y2, z2 = project(phi, theta + rotation + 0.1)
            if z1 > 0 and z2 > 0 then -- Only draw visible parts
                cairo_move_to(cr, config.xc + config.radius * x1, config.yc - config.radius * y1)
                cairo_line_to(cr, config.xc + config.radius * x2, config.yc - config.radius * y2)
            end
        end
        cairo_stroke(cr)
    end

    -- Add shading for a realistic appearance (optional)
    local light_dir = { x = -1, y = 0, z = 0 } -- Light source direction
    local offset = 60
    local shading = cairo_pattern_create_radial(
        config.xc + config.radius * light_dir.x * 0.6 + offset,
        config.yc - config.radius * light_dir.y * 0.6,
        config.radius * 0.1,
        config.xc - config.radius * light_dir.x * 0.6 + offset,
        config.yc + config.radius * light_dir.y * 0.6,
        config.radius * 1.2
    )
    cairo_pattern_add_color_stop_rgba(shading, 0.0, 0, 0, 0, 0.0)
    cairo_pattern_add_color_stop_rgba(shading, 0.5, 0, 0, 0, 0.0)
    cairo_pattern_add_color_stop_rgba(shading, 1.0, 0, 0, 0, 0.25)
    cairo_set_source(cr, shading)
    cairo_arc(cr, config.xc, config.yc, config.radius, 0, 2 * math.pi)
    cairo_fill(cr)
    cairo_pattern_destroy(shading)
end

-- Function to draw city pins and labels
local function draw_cities(cr)
    -- City data including name, coordinates, color, and pin length
    local cities = {
        { name = "Amsterdam", lat = 52.37, lon = 4.89, color = hex_to_rgb("#00D1FF"), pin_length = 50, pin_angle = -90 },
        { name = "Paris", lat = 48.85, lon = 2.35, color = hex_to_rgb("#00FFEF"), pin_length = 35 },
        { name = "London", lat = 51.51, lon = -0.13, color = hex_to_rgb("#FFD300"), pin_length = 15 },                
        { name = "New York", lat = 40.71, lon = -74.01, color = hex_to_rgb("#FF4B00"), pin_length = 50 },
        { name = "Washington", lat = 38.90, lon = -77.04, color = hex_to_rgb("#00FF94"), pin_length = 35 },
        { name = "Las Vegas", lat = 36.17, lon = -115.14, color = hex_to_rgb("#FF1493"), pin_length = 15 },
        { name = "Beijing", lat = 39.90, lon = 116.40, color = hex_to_rgb("#7CFC00"), pin_length = 30 },
        { name = "Tokyo", lat = 35.68, lon = 139.76, color = hex_to_rgb("#FF006E"), pin_length = 20, pin_angle = -90 },               
        { name = "Brasilia", lat = -15.79, lon = -47.88, color = hex_to_rgb("#ff5782"),pin_length = 30 },        
        { name = "Buenos Aires", lat = -34.61, lon = -58.38, color = hex_to_rgb("#FF8C00") },
        { name = "Cape Town", lat = -33.92, lon = 18.42, color = hex_to_rgb("#8A2BE2") },
        { name = "Suva", lat = -18.14, lon = 178.44, color = hex_to_rgb("#a47de8"),pin_length = 50 },        
        { name = "Wellington", lat = -41.29, lon = 174.78, color = hex_to_rgb("#4d94ff"),pin_length = 50 },
        { name = "Canberra", lat = -35.28, lon = 149.13, color = hex_to_rgb("#00BFFF"),pin_length = 15 },
        { name = "Jakarta", lat = -6.21, lon = 106.85, color = hex_to_rgb("#A52A2A") },
    }

    -- Calculate rotation based on current time
    local rotation = get_rotation()

    -- Iterate through each city to plot its pin and label
    for _, city in ipairs(cities) do
        local phi = city.lat * math.pi / 180 -- Convert latitude to radians
        local theta = (city.lon * math.pi / 180) + rotation -- Convert longitude to radians and add rotation
        local x, y, z = project(phi, theta) -- Project 3D coordinates to 2D space

        if z > 0 then -- Only draw cities on the visible side of the globe
            -- Calculate pin origin on the globe
            local px = config.xc + config.radius * x
            local py = config.yc - config.radius * y

            -- Draw a small dot where the pin touches the globe
            local dot_radius = 2.5
            cairo_arc(cr, px, py, dot_radius, 0, 2 * math.pi)
            cairo_set_source_rgba(cr, city.color.r, city.color.g, city.color.b, 1)
            cairo_fill(cr)

            -- Calculate pin endpoint
            local angle = math.rad(city.pin_angle or -90)
            local length = city.pin_length or config.pin_length
            local pin_x = px + math.cos(angle) * length
            local pin_y = py + math.sin(angle) * length

            -- Draw the pin line
            cairo_set_source_rgba(cr, city.color.r, city.color.g, city.color.b, 1)
            cairo_set_line_width(cr, 1)
            cairo_move_to(cr, px, py)
            cairo_line_to(cr, pin_x, pin_y)
            cairo_stroke(cr)

            -- Draw the pin head
            cairo_arc(cr, pin_x, pin_y, config.pin_radius, 0, 2 * math.pi)
            cairo_fill(cr)

            -- Optionally add a border around the pin head for better visibility
            cairo_set_source_rgba(cr, 0, 0, 0, 0.5) -- Dark border
            cairo_set_line_width(cr, 1)
            cairo_arc(cr, pin_x, pin_y, config.pin_radius, 0, 2 * math.pi)
            cairo_stroke(cr)

            -- Prepare text for the label
            cairo_select_font_face(cr, config.font_name, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
            cairo_set_font_size(cr, config.font_size)
            local extents = cairo_text_extents_t:create()
            cairo_text_extents(cr, city.name, extents)

            -- Load flag image
            local padding = 3
            local flag_file = flags[city.name]
            local flag_surface
            local flag_width, flag_height = 0, 0
            local scale = 0.2 -- Scale the flag to approximately 19px height

            if flag_file then
                local flag_path = flag_dir .. flag_file
                flag_surface = cairo_image_surface_create_from_png(flag_path)
                if cairo_surface_status(flag_surface) == 0 then
                    flag_width = cairo_image_surface_get_width(flag_surface) * scale
                    flag_height = cairo_image_surface_get_height(flag_surface) * scale
                else
                    flag_surface = nil
                end
            end

            -- Calculate positions for text and flag with label_offset
            local total_height = math.max(extents.height, flag_height)
            local label_offset = config.label_offset

            local total_width = (flag_width > 0 and flag_width + 4 or 0) + extents.width + 2 * padding
            local total_height = math.max(extents.height, flag_height)

            local box_x = pin_x - (total_width / 2)
            local box_y = pin_y - label_offset - (total_height / 2) - padding
            local box_w = total_width
            local box_h = math.max(extents.height, flag_height) + 2 * padding

            -- Positie van vlag
            local flag_x = box_x + padding
            local flag_y = box_y + (box_h - flag_height) / 2

            -- Positie van tekst
            local label_x = flag_x + (flag_width > 0 and flag_width + 4 or 0)
            local label_y = box_y + box_h / 2 + extents.height / 2

            local box_w = (flag_width > 0 and flag_width + 4 or 0) + extents.width + 2 * padding
            local box_h = math.max(extents.height, flag_height) + 2 * padding


            -- Draw the label background with border
            rounded_rectangle(cr, box_x, box_y, box_w, box_h, 4)

            -- Fill the label background
            cairo_set_source_rgba(cr, city.color.r, city.color.g, city.color.b, 1)
            cairo_fill_preserve(cr)

            -- Draw the border (black, semi-transparent)
            cairo_set_source_rgba(cr, 0, 0, 0, 0.4)
            cairo_set_line_width(cr, 1)
            cairo_stroke(cr)

            -- Draw the flag image (if available)
            if flag_surface then
                cairo_save(cr)
                cairo_translate(cr, box_x + padding, box_y + (box_h - flag_height) / 2)
                cairo_scale(cr, scale, scale)
                cairo_set_source_surface(cr, flag_surface, 0, 0)
                cairo_paint(cr)
                cairo_restore(cr)
                cairo_surface_destroy(flag_surface)
            end

            -- Draw the city name text
            local label_color = hex_to_rgb(config.label_color_hex)
            cairo_set_source_rgba(cr, label_color.r, label_color.g, label_color.b, 1)
            cairo_move_to(cr, label_x, label_y)
            cairo_show_text(cr, city.name)
        end
    end
end

-- Main function to draw the globe and cities
function conky_draw_globe()
    if conky_window == nil then return "" end -- Exit if Conky window is not available

    -- Create the drawing surface and context
    local cs = cairo_xlib_surface_create(
        conky_window.display,
        conky_window.drawable,
        conky_window.visual,
        conky_window.width,
        conky_window.height
    )
    local cr = cairo_create(cs)

    -- Clip everything except the rightmost 8 pixels
    local clip_width = conky_window.width - 8
    local clip_height = conky_window.height
    cairo_rectangle(cr, 0, 0, clip_width, clip_height)
    cairo_clip(cr)

    -- Draw the globe and cities
    draw_globe(cr)
    draw_cities(cr)

    -- Clean up resources
    cairo_destroy(cr)
    cairo_surface_destroy(cs)
    return ""
end