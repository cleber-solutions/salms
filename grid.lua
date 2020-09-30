local grid = {}

grid_directions = {
    up = {0, -1},
    down = {0, 1},
    left = {-1, 0},
    right = {1, 0}
}
grid_directions_names = {"up", "right", "down", "left"}
grid_opposite_directions = {
    up = "down",
    down = "up",
    left = "right",
    right = "left"
}

function draw_grid()
    love.graphics.setColor(0.4, 0.4, 0.4)

    -- Lines
    line = y_offset % (cell_h) - cell_h
    while (line < wh) do
        love.graphics.line(0, line, ww, line)
        love.graphics.line(0, line + grid_space_h, ww, line + grid_space_h)
        line = line + grid_h + grid_space_h
    end

    -- Columns
    column = x_offset % (cell_w) - cell_w
    while (column < ww) do
        love.graphics.line(column, 0, column, wh)
        love.graphics.line(column + grid_space_w, 0, column + grid_space_w, wh)
        column = column + grid_w + grid_space_w
    end
end

function highlight_cell(x, y)
    gx, gy = coords_to_grid(x, y)
    highlighted_rectangle = {gx, gy}
end

-- Coordinates to/from grid
function coords_from_grid(x, y)
    return
        x * cell_w + grid_space_w + x_offset,
        y * cell_h + grid_space_h + y_offset
end

function coords_to_grid(x, y)
    return 
        math.floor((x - x_offset) / cell_w),
        math.floor((y - y_offset) / cell_h)
end

return grid
