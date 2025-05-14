-- images.lua
-- Loads and draws flags as PNG images with scalable height and width
-- by @wim66
-- v 0.5 May 14, 2025

require 'cairo'

-- Function to load and draw an image with a configurable height
-- Parameters:
--   cr (cairo context): The Cairo drawing context
--   path (string): The file path to the PNG image
--   x (number): The x-coordinate where the image should be drawn
--   y (number): The y-coordinate where the image should be drawn
--   height (number): The desired height of the image
function draw_image(cr, path, x, y, height)
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