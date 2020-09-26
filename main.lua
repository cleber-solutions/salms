components = require "components"
schema = require("schema")
grid = require "grid"

function love.load()
    -- image = love.graphics.newImage("cake.jpg")
    x_offset = 0
    y_offset = 0

    draw_timer = 0
    beat_timer = 0
    beat_interval = 0.75
    beat_counter = 0
    step_size = 7
    love.window.vsync = true

    grid_w = 140
    grid_h = 80
    grid_space_w = math.floor(grid_w / 3)
    grid_space_h = math.floor(grid_h / 2)
    cell_w = grid_w + grid_space_w
    cell_h = grid_h + grid_space_h

    should_draw_grid = false

    highlighted_rectangle = nil

    love.graphics.setNewFont(12)
    love.graphics.setColor(0,0,0)
    love.graphics.setBackgroundColor(255,255,255)

    -- Initialize the schema:
    schema.init()
end

function love.draw()
    if should_draw_grid then
        draw_grid()
    end

    wh = love.graphics.getHeight()
    ww = love.graphics.getWidth()

    if highlighted_rectangle then
        rx, ry = coords_from_grid(unpack(highlighted_rectangle))
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.rectangle("fill", rx, ry, grid_w, grid_h)
    end

    for idx, c in ipairs(components_list) do
        rx, ry = coords_from_grid(unpack(c["coordinates"]))

        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle("line", rx, ry, grid_w, grid_h)

        -- Draw only VISIBLE components
        if not (rx < -grid_w or ry < -grid_h or rx > ww or ry > wh) then
            if c["active"] then
                love.graphics.setColor(0, 1, 0)
                love.graphics.rectangle("fill", rx, ry, grid_w, grid_h)
            end

            c:draw(rx, ry)

            -- Connect to neighbours:
            for idx, connector in ipairs(c["connectors"]) do
                cx1, cy1, cx2, cy2 = unpack(connector)
                love.graphics.line(
                    cx1 + rx, cy1 + ry,
                    cx2 + rx, cy2 + ry
                )
            end
        end
    end
end

function love.update(dt)
    draw_timer = draw_timer + dt
    beat_timer = beat_timer + dt
    if draw_timer < 0.025 then
        return
    end
    draw_timer = 0

    if beat_timer > beat_interval then
        beat(beat_timer)
        beat_timer = 0
    end

    if love.keyboard.isDown("q") then
        love.window.close()
        os.exit()
    end

    if love.keyboard.isDown("left") then
        x_offset = x_offset + step_size
    elseif love.keyboard.isDown("right") then
        x_offset = x_offset - step_size
    end

    if love.keyboard.isDown("up") then
        y_offset = y_offset + step_size
    elseif love.keyboard.isDown("down") then
        y_offset = y_offset - step_size
    end

    if love.keyboard.isDown("x") then
        c = components_list[1]
        if c then
            c:action()
        end
    end
end

function love.mousepressed(x, y, button, istouch)
    if button == 1 then
        highlight_cell(x, y)
    elseif button == 2 then
        components.run_action(x, y)
    end
end

------------------------------------------------
function beat(t)
    beat_counter = (beat_counter + 1) % 1000

    for idx, c in ipairs(components_list) do
        c:beat()
    end
end
