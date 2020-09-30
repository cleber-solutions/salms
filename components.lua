local components = {}

components_matrix = {}
components_list = {}

status_colors = {
    is_disabled = {0.8, 0.8, 0.8},
    action_was_called = {1, 0.5, 0.25},
    has_pending_call = {0.25, 1, 0.25},
    has_pending_response = {0.5, 0.25, 1},
    is_processing_calls = {0.25, 1, 1},
    is_active = {1, 0.25, 0.25}
}

function components.add(component)
    -- Test for each neighbour.
    -- If it exists, create a new connector:
    x, y = unpack(component.coordinates)

    -- Actually add component to the components_list and components_matrix
    table.insert(components_list, component)

    if not components_matrix[x] then
        components_matrix[x] = {}
    end

    components_matrix[x][y] = component
end

function components.load_neighbourhood()
    for idx, c in ipairs(components_list) do
        c:load_connectors()
    end
end

--
function components.activate(x, y)
    gx, gy = coords_to_grid(x, y)
    if components_matrix[gx] then
        c = components_matrix[gx][gy]
        if c then
            c.active = true
        end
    end
end

function components.run_action(x, y)
    gx, gy = coords_to_grid(x, y)
    if components_matrix[gx] then
        c = components_matrix[gx][gy]
        if c then
            c:do_call_action()
        end
    end
end

Component = {
    success_response = 0,
    failure_response = 1,
    call_action_message = "Doing something",
    output_type = nil,
    fanout_index = 1,
}
Component.__index = Component
function Component:create(base, name, x, y)
    setmetatable(base, Component)
    base.__index = base

    local object = {}
    setmetatable(object, base)

    object.name = name
    object.label = name
    object.coordinates = {x, y}

    object.status = nil
    object.action_called = false
    object.active = false
    object.disabled = false

    object.calls_list = {}
    object.calls_list_len = 0
    object.response_list = {}
    object.response_list_len = 0
    object.pending_call_len = 0
    object.waiting = false

    return object
end

function Component:load_connectors()
    x, y = unpack(self.coordinates)

    connectors = {}

    neighbourhood = {
        up = {0, -1, {grid_w / 2, 0, grid_w / 2, -grid_space_h}}, -- up
        down = {0, 1, {grid_w / 2, grid_h, grid_w / 2, grid_h + grid_space_h}}, -- down
        left = {-1, 0, {0, grid_h / 2, -grid_space_w, grid_h / 2}}, -- left
        right = {1, 0, {grid_w, grid_h / 2, grid_w + grid_space_w, grid_h / 2}} -- right
    }

    for direction_name, coords in pairs(neighbourhood) do
        ox, oy, line_points = unpack(coords)
        rx = x + ox
        ry = y + oy

        line = components_matrix[rx]
        if line then
            cell = line[ry]
            if cell then
                connectors[direction_name] = {line_points, 0}
            else
                connectors[direction_name] = nil
            end
        end
    end

    self.connectors = connectors
end

function Component:do_call_action()
    if not self.action_called then
        self.action_called = true
        self:action()
    end
end

function Component:action()
    self.disabled = not self.disabled
    if self.disabled then
        self.status = "DISABLED"
    else
        self.status = nil
    end
end

function Component:draw(rx, ry)
    color = nil
    if self.disabled then
        color = status_colors.is_disabled
    elseif self.action_called then
        color = status_colors.action_was_called
    elseif self.pending_call_len > 0 then
        color = status_colors.has_pending_call
    elseif self.response_list_len > 0 then
        color = status_colors.has_pending_response
    elseif self.calls_list_len > 0 then
        color = status_colors.is_processing_calls
    elseif self.active then
        color = status_colors.is_active
    end
    if color then
        love.graphics.setColor(unpack(color))
        love.graphics.rectangle("fill", rx, ry, grid_w, grid_h)
    end

    -- Icon
    if self.icon then
        icon = love.graphics.newImage("icons/"..self.icon)
        love.graphics.draw(icon, rx + 2, ry + 2, 0, 1, 1, 0, 0, 0, 0)
    end

    -- Label and status
    love.graphics.setColor(0, 0, 0)
    love.graphics.printf(
        self.label,
        rx + 36, ry + 5,
        grid_w - 36,
        'center'
    )

    if self.status then
        love.graphics.printf(
            self.status,
            rx + 36, ry + 30,
            grid_w - 36,
            'center'
        )
    end

    self:post_draw(rx, ry)
end

function Component:post_draw(rx, ry)
end

-- 
function Component:call_neighbours(input_type, argument, context)
    x, y = unpack(self.coordinates)

    successful_calls = 0

    self.fanout_index = 1
    for i=0,3 do
        called_succesfully = self:do_fanout_to_neighbours(input_type, argument, context)
        if called_succesfully then
            successful_calls = successful_calls + 1
        end
    end

    return successful_calls
end

function Component:do_fanout_to_neighbours(input_type, argument, context)
    x, y = unpack(self.coordinates)

    called_succesfully = false

    direction_name = grid_directions_names[self.fanout_index]
    pos = grid_directions[direction_name]
    self.fanout_index = (self.fanout_index % 4) + 1

    ox, oy = unpack(pos)
    if components_matrix[x+ox] then
        n = components_matrix[x+ox][y+oy]
        if n and n.input_type == input_type then
            called_succesfully = self:call_neighbour(n, argument, self, context)
            if called_succesfully then
                -- Adjust connector redness:
                self.connectors[direction_name][2] = 1
                opposite_direction = grid_opposite_directions[direction_name]
                n.connectors[opposite_direction][2] = 1
            end
        end
    end

    return called_succesfully
end

function Component:fanout_to_neighbours(input_type, argument, context)
    for i=0,3 do
        called_succesfully = self:do_fanout_to_neighbours(input_type, argument, context)
        if called_succesfully then
            return true
        end
    end
    return false
end

function Component:call_neighbour(n, argument, caller, context)
    if n.disabled then
        self.status = n.label.." is disabled"
        return false
    end

    -- TODO: do not manipulate neighbour attributes here. Call a proper method.
    table.insert(n.calls_list, CallData:create(caller, argument, context))
    self.pending_call_len = self.pending_call_len + 1
    return true
end

function Component:respond(call_args, response, context)
    response_data = ResponseData:create(self, response, call_args.context)
    call_args.caller:receive_response(response_data)
end

function Component:receive_response(response_data)
    table.insert(self.response_list, response_data)
    self.pending_call_len = self.pending_call_len - 1
    
    if self.pending_call_len == 0 then
        self:last_call_resolved()
    end
end

function Component:last_call_resolved()
    -- self.active = false
end

ResponseData = {}
function ResponseData:create(responder, response, context)
    return {
        responder = responder,
        response = response,
        step = -1,
        context = context
    }
end

CallData = {}
function CallData:create(caller, argument, context)
    return {
        argument = argument,
        caller = caller,
        step = -1,
        waiting = false,
        context = context
    }
end

--
function Component:beat()
    self:process_calls()
    self:process_responses()
    self:post_beat()

    -- Reset some states
    self.action_called = false

    for direction_name, connector_data in pairs(self.connectors) do
        redness = connector_data[2]
        if redness > 0.5 then
            connector_data[2] = redness - 0.05
        end
    end


end

function Component:post_beat()
end
--

-- Calling and responding:
function Component:call(method_name, argument, context)
    self.status = "call "..method_name
    self:call_neighbours(method_name, argument, context)
end

-- CALLS
function Component:process_calls()
    len = 0
    new_list = {}
    for idx, call_args in ipairs(self.calls_list) do
        if not call_args.waiting then
            call_args.step = call_args.step + 1
            done = self:call_step(call_args)
            if not done then
                table.insert(new_list, call_args)
                len = len + 1
            end
        end
    end
    self.calls_list = new_list
    self.calls_list_len = len
end

function Component:call_step(call_args)
    step = call_args.step

    if step == 0 then
        self.status = "CALL: "..call_args["argument"]
    elseif step == 1 then
        self.status = "Processing..."
    elseif step == 2 then
        done = self:call_action(call_args)
        if done then
            return true
        end
    elseif step == 3 then
        self.status = "Done"
        self:respond(call_args, self.success_response)
    elseif step == 4 then
        self.status = nil
        return true  -- done
    end
end

function Component:call_action(call_args)
    self.status = self.call_action_message

    if self.output_type then
        n_count = self:call_neighbours(self.output_type, "DATA", nil)
        if n_count == 0 then
            self:respond(call_args, self.failure_response)
            return true
        end
    end
end

-- RESPONSES
function Component:process_responses()
    len = 0
    new_list = {}
    for idx, response_data in ipairs(self.response_list) do
        response_data.step = response_data.step + 1
        done = self:response_step(response_data)
        if not done then
            -- https://stackoverflow.com/questions/12394841/safely-remove-items-from-an-array-table-while-iterating
            -- Search for the "Efficiency" answer.
            table.insert(new_list, response_data)
            len = len + 1
        end
    end
    self.response_list = new_list
    self.response_list_len = len
end

function Component:response_step(response_data)
    step = response_data.step

    if step == 0 then
        self:response_step_zero(response_data)
    elseif step == 1 then
        self:response_step_one(response_data)
    elseif step == 2 then
        self.status = nil
        return true -- done
    end
end

function Component:response_step_zero(response_data)
    self.status = "Response: "..tostring(response_data.response)
end

function Component:response_step_one(response_data)
    if response_data.context then
        response_data.context.waiting = false
    end
end

return components
