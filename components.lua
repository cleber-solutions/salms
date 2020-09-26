local components = {}

components_matrix = {}
components_list = {}

function components.add(x, y, component)
    -- Test for each neighbour.
    -- If it exists, create a new connector:
    connectors = {}
    if components_matrix[x-1] and components_matrix[x-1][y] then
        table.insert(connectors, {0, grid_h / 2, -grid_space_w, grid_h / 2}) -- left
    elseif components_matrix[x+1] and components_matrix[x+1][y] then
        table.insert(connectors, {grid_w, grid_h / 2, grid_w + grid_space_w, grid_h / 2})  -- right
    elseif components_matrix[x] then
        if components_matrix[x][y-1] then
            table.insert(connectors, {grid_w / 2, 0, grid_w / 2, -grid_space_h})  -- up
        elseif components_matrix[x][y+1] then
            table.insert(connectors, {grid_w / 2, grid_h, grid_w / 2, grid_h + grid_space_h})  -- down
        end
    end
    component.connectors = connectors

    -- Actually add component to the components_list and components_matrix
    table.insert(components_list, component)

    if not components_matrix[x] then
        components_matrix[x] = {}
    end

    components_matrix[x][y] = component
end

--
--
function components.activate(x, y)
    gx, gy = coords_to_grid(x, y)
    if components_matrix[gx] then
        c = components_matrix[gx][gy]
        if c then
            c["active"] = true
        end
    end
end

function components.run_action(x, y)
    gx, gy = coords_to_grid(x, y)
    if components_matrix[gx] then
        c = components_matrix[gx][gy]
        if c then
            c:action()
        end
    end
end

Component = {}
Component.__index = Component
function Component:create(base, name, x, y)
    local object = base
    setmetatable(object, Component)

    object.name = name
    object.label = name
    object.coordinates = {x, y}
    object.status = nil
    object.input_list = {}
    object.response_list = {}
    object.waiting = false

    return object
end

function Component:action()
    print("ACTION")
end

function Component:draw(rx, ry)
    love.graphics.setColor(0, 0, 0)
    love.graphics.printf(
        self.label,
        rx, ry + 15,
        grid_w,
        'center'
    )

    if self.status then
        love.graphics.printf(
            self.status,
            rx, ry + 30,
            grid_w,
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

    neighbours_positions = {
        {0, 1}, {0, -1},
        {1, 0}, {-1, 0}
    }

    for _, pos in ipairs(neighbours_positions) do
        ox, oy = unpack(pos)

        if components_matrix[x+ox] then
            n = components_matrix[x+ox][y+oy]
            if n and n.input_type == input_type then
                self:call_neighbour(n, argument, self, context)
                return
            end
        end
    end
end


function Component:call_neighbour(n, argument, caller, context)
    table.insert(n.input_list, CallData:create(caller, argument, context))
end

function Component:respond(call_args, response, context)
    response_data = ResponseData:create(self, response, call_args.context)
    call_args.caller:receive_response(response_data)
end

function Component:receive_response(response_data)
    table.insert(self.response_list, response_data)
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
end

function Component:post_beat()
end
--

-- Calling and responding:
function Component:call(method_name, argument, context)
    if not self.status then
        self.status = "call "..method_name
        self:call_neighbours(method_name, argument, context)
        self.active = true
    end
end

-- CALLS
function Component:process_calls()
    for idx, call_args in ipairs(self.input_list) do
        if not call_args.waiting then
            call_args.step = call_args.step + 1
            done = self:call_step(call_args)
            if done then
                table.remove(self.input_list, idx)
            end
        end
    end
end

function Component:call_step(call_args)
    step = call_args.step

    if step == 0 then
        self.status = "CALL: "..call_args["argument"]
        self.active = true
    elseif step == 1 then
        self.status = "Processing..."
    elseif step == 2 then
        self:call_action(call_args)
    elseif step == 3 then
        self.status = "Done"
        self:respond(call_args, "received")
    elseif step == 4 then
        self.status = nil
        self.active = false
        return true  -- done
    end
end

function Component:call_action(call_args)
    self.status = "Done"
end

-- RESPONSES
function Component:process_responses()
    resolved = 0
    for idx, response_data in ipairs(self.response_list) do
        response_data.step = response_data.step + 1
        done = self:response_step(response_data)
        if done then
            table.remove(self.response_list, idx)
            resolved = resolved + 1
        end
    end

    if resolved > 0 then
        self.active = false
    end
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
    self.status = "Response: "..response_data.response
end

function Component:response_step_one(response_data)
    if response_data.context then
        response_data.context.waiting = false
    end
end

return components
