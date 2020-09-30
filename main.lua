components = require "components"
grid = require "grid"

function love.load()
    love.window.setTitle("salms: Software Architecture Live Diagrams")
    love.window.setMode(1280, 750, {resizable=true,centered=true,minwidth=800,minheight=600})
    love.window.maximize()
    wh = love.graphics.getHeight()
    ww = love.graphics.getWidth()

    x_offset = 0
    y_offset = 0

    draw_timer = 0
    beat_timer = 0
    beat_interval = 0.1
    beat_counter = 0
    step_size = 15

    -- Fine tuning:
    -- TODO: load these from somewhere else
    grid_w = 170
    grid_h = 90

    beat_debounce = false

    grid_space_w = math.floor(grid_w / 3)
    grid_space_h = math.floor(grid_h / 2)
    cell_w = grid_w + grid_space_w
    cell_h = grid_h + grid_space_h

    love.graphics.setLineWidth(2)

    should_draw_grid = false

    highlighted_rectangle = nil

    love.graphics.setNewFont(12)
    love.graphics.setColor(0,0,0)
    love.graphics.setBackgroundColor(255,255,255)

    -- Load desired schema:
    schema_path = arg[2]
    if schema_path == nil then
        schema_path = "schema.lua"
    end
    schema = dofile(schema_path)

    -- Initialize the schema:
    schema.init()
end

function love.draw()
    if should_draw_grid then
        draw_grid()
    end

    draw_legend()

    love.graphics.setColor(0, 0, 0)
    love.graphics.print(beat_counter, 5, 5)

    if highlighted_rectangle then
        rx, ry = coords_from_grid(unpack(highlighted_rectangle))
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.rectangle("fill", rx, ry, grid_w, grid_h)
    end

    for idx, c in ipairs(components_list) do
        rx, ry = coords_from_grid(unpack(c["coordinates"]))


        -- Draw only VISIBLE components
        if not (rx < -grid_w or ry < -grid_h or rx > ww or ry > wh) then
            love.graphics.setColor(0.2, 0.2, 0.2)
            love.graphics.rectangle("line", rx, ry, grid_w, grid_h)

            c:draw(rx, ry)

            -- Connect to neighbours:
            for direction_name, connector_data in pairs(c.connectors) do
                if connector_data then
                    connector, redness = unpack(connector_data)
                    cx1, cy1, cx2, cy2 = unpack(connector)

                    love.graphics.setColor(redness, 0.5, 0.5)

                    love.graphics.line(
                        cx1 + rx, cy1 + ry,
                        cx2 + rx, cy2 + ry
                    )
                end
            end
        end
    end
end

function draw_legend()
    x = 5
    size = 12
    space = 4
    y = wh - size - 5
    for name, color in pairs(status_colors) do
        love.graphics.setColor(0, 0, 0)
        love.graphics.print(name, x + size + space, y)
        love.graphics.setColor(unpack(color))
        love.graphics.rectangle("fill", x, y, size, size)

        y = y - size - space
    end
end

function love.update(dt)
    draw_timer = draw_timer + dt
    if draw_timer < 0.1 then
        -- diff = draw_timer - 0.1
        love.timer.sleep(0.05)
        return
    end
    draw_timer = 0

    wh = love.graphics.getHeight()
    ww = love.graphics.getWidth()

    if love.keyboard.isDown("q") then
        love.window.close()
        os.exit()
    elseif love.keyboard.isDown("space") then
        if not beat_debounce then
            beat()
            beat_debounce = true
        end
    end

    if beat_debounce then
        beat_timer = beat_timer + dt
        if beat_timer > beat_interval then
            beat_timer = 0
            beat_debounce = false
        end
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
            c:do_call_action()
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
function beat()
    beat_counter = (beat_counter + 1) % 1000

    for idx, c in ipairs(components_list) do
        c:beat()
    end
end
