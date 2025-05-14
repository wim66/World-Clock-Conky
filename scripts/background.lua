-- background.lua
-- World Clocks drawn with Cairo and flags
-- by @wim66
-- v 0.5 May 14, 2025

-- === Required Cairo Modules ===
require 'cairo'
local status, cairo_xlib = pcall(require, 'cairo_xlib')

if not status then
    -- Fallback for environments without cairo_xlib
    cairo_xlib = setmetatable({}, {
        __index = function(_, key)
            return _G[key]
        end
    })
end

-- === Utility ===
local unpack = table.unpack or unpack

-- === All drawable elements ===
local boxes_settings = {
    {
        type = "image",
        x = 0, y = 6, w = 455, h = 298,
        centre_x = true,
        rotation = 0,
        draw_me = true,
        image_path = "images/earth.png"
    },
    -- Background
    {
        type = "background",
        x = 0, y = 0, w = 468, h = 308,
        centre_x = true,
        corners = { 20, 20, 20, 20 },
        rotation = 0,
        draw_me = true,
        colour = { { 1, 0x1d1d2e, 0.5 } }
    },
    {
        type = "border",
        x = 0, y = 0, w = 470, h = 310,
        centre_x = true,
        corners = { 20, 20, 20, 20 },
        rotation = 0,
        draw_me = true,
        border = 8,
        colour = {
            { 0.00, 0x0D47A1, 1 }, -- Navy blue
            { 0.25, 0x42A5F5, 1 }, -- Bright blue
            { 0.50, 0xBBDEFB, 1 }, -- Light blue highlight
            { 0.75, 0x42A5F5, 1 },
            { 1.00, 0x0D47A1, 1 }
        },
        linear_gradient = { 0, 0, 470, 0 }
    }
}

-- === Helper: Convert hex to RGBA ===
local function hex_to_rgba(hex, alpha)
    return ((hex >> 16) & 0xFF) / 255, ((hex >> 8) & 0xFF) / 255, (hex & 0xFF) / 255, alpha
end

-- === Helper: Draw custom rounded rectangle ===
local function draw_custom_rounded_rectangle(cr, x, y, w, h, r)
    local tl, tr, br, bl = unpack(r)

    cairo_new_path(cr)
    cairo_move_to(cr, x + tl, y)
    cairo_line_to(cr, x + w - tr, y)
    if tr > 0 then
        cairo_arc(cr, x + w - tr, y + tr, tr, -math.pi / 2, 0)
    else
        cairo_line_to(cr, x + w, y)
    end
    cairo_line_to(cr, x + w, y + h - br)
    if br > 0 then
        cairo_arc(cr, x + w - br, y + h - br, br, 0, math.pi / 2)
    else
        cairo_line_to(cr, x + w, y + h)
    end
    cairo_line_to(cr, x + bl, y + h)
    if bl > 0 then
        cairo_arc(cr, x + bl, y + h - bl, bl, math.pi / 2, math.pi)
    else
        cairo_line_to(cr, x, y + h)
    end
    cairo_line_to(cr, x, y + tl)
    if tl > 0 then
        cairo_arc(cr, x + tl, y + tl, tl, math.pi, 3 * math.pi / 2)
    else
        cairo_line_to(cr, x, y)
    end
    cairo_close_path(cr)
end

-- === Helper: Center X position ===
local function get_centered_x(canvas_width, box_width)
    return (canvas_width - box_width) / 2
end

-- === Helper: Draw an image ===
local function draw_image(cr, image_path, x, y, w, h, rotation, centre_x, canvas_width)
    local image_surface = cairo_image_surface_create_from_png(image_path)
    local status = cairo_surface_status(image_surface)
    if status ~= 0 then
        print("Failed to load image: " .. image_path)
        return
    end

    local img_w = cairo_image_surface_get_width(image_surface)
    local img_h = cairo_image_surface_get_height(image_surface)

    -- Scale to exact w and h, ignoring aspect ratio
    local scale_x = w / img_w
    local scale_y = h / img_h

    -- Adjust position for centering
    if centre_x then
        x = get_centered_x(canvas_width, w)
    end

    -- Calculate center for rotation
    local cx, cy = x + w / 2, y + h / 2
    local angle = (rotation or 0) * math.pi / 180

    cairo_save(cr)
    cairo_translate(cr, cx, cy)
    cairo_rotate(cr, angle)
    cairo_scale(cr, scale_x, scale_y)
    cairo_translate(cr, -img_w / 2, -img_h / 2)
    cairo_set_source_surface(cr, image_surface, 0, 0)
    cairo_paint(cr)
    cairo_restore(cr)
    cairo_surface_destroy(image_surface)
end

-- === Main drawing function ===
function conky_draw_background()
    if conky_window == nil then
        return
    end

    local cs = cairo_xlib_surface_create(
        conky_window.display,
        conky_window.drawable,
        conky_window.visual,
        conky_window.width,
        conky_window.height
    )
    local cr = cairo_create(cs)
    local canvas_width = conky_window.width

    cairo_save(cr)

    for _, box in ipairs(boxes_settings) do
        if box.draw_me then
            local x, y, w, h = box.x, box.y, box.w, box.h
            if box.centre_x then
                x = get_centered_x(canvas_width, w)
            end

            local cx, cy = x + w / 2, y + h / 2
            local angle = (box.rotation or 0) * math.pi / 180

            if box.type == "background" then
                cairo_save(cr)
                cairo_translate(cr, cx, cy)
                cairo_rotate(cr, angle)
                cairo_translate(cr, -cx, -cy)
                cairo_set_source_rgba(cr, hex_to_rgba(box.colour[1][2], box.colour[1][3]))
                draw_custom_rounded_rectangle(cr, x, y, w, h, box.corners)
                cairo_fill(cr)
                cairo_restore(cr)

            elseif box.type == "border" then
                local grad = cairo_pattern_create_linear(unpack(box.linear_gradient))
                for _, color in ipairs(box.colour) do
                    cairo_pattern_add_color_stop_rgba(grad, color[1], hex_to_rgba(color[2], color[3]))
                end
                cairo_set_source(cr, grad)
                cairo_save(cr)
                cairo_translate(cr, cx, cy)
                cairo_rotate(cr, angle)
                cairo_translate(cr, -cx, -cy)
                cairo_set_line_width(cr, box.border)
                draw_custom_rounded_rectangle(
                    cr,
                    x + box.border / 2,
                    y + box.border / 2,
                    w - box.border,
                    h - box.border,
                    {
                        math.max(0, box.corners[1] - box.border / 2),
                        math.max(0, box.corners[2] - box.border / 2),
                        math.max(0, box.corners[3] - box.border / 2),
                        math.max(0, box.corners[4] - box.border / 2)
                    }
                )
                cairo_stroke(cr)
                cairo_restore(cr)
                cairo_pattern_destroy(grad)

            elseif box.type == "image" then
                draw_image(cr, box.image_path, x, y, w, h, box.rotation, box.centre_x, canvas_width)
            end
        end
    end

    cairo_restore(cr)
    cairo_destroy(cr)
    cairo_surface_destroy(cs)
end