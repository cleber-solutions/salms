RPC_Service = {
    input_type = "RPC",
    call_steps = {},
    icon = "function.png"
}

function RPC_Service:call_action(call_args)
    first_step = self.call_steps[1]
    if first_step then
        call_type, call_argument, status = unpack(first_step)
        self.status = status
        call_args._next_step = 2

        self:call_neighbours(call_type, call_argument, call_args)
        call_args.waiting = true
    end
end

function RPC_Service:response_step_one(response_data)
    last_call_type = nil

    next_step_index = response_data.context._next_step
    next_step = self.call_steps[next_step_index]

    if next_step then
        call_type, call_argument, status = unpack(next_step)
        self.status = status

        ctx = response_data.context
        ctx._next_step = next_step_index + 1
        self:call_neighbours(call_type, call_argument, ctx)
    else
        self.status = "Response: "..response_data.response
        response_data.context.waiting = false
    end
end
