AMQP_Queue = {
    input_type = "amqp.topic",
    messages = {},
    messages_counter = 0
}

function AMQP_Queue:call_action(call_args)
    self.status = "Receiving..."
    table.insert(self.messages, call_args.argument)
    self.messages_counter = self.messages_counter + 1
    -- self:call_neighbours("db", "persist", call_args)
end

function AMQP_Queue:post_draw(rx, ry)
    if self.messages_counter == 0 then
        n = "empty"
    else
        n = self.messages_counter
    end

    love.graphics.printf(
        "["..n.."]",
        rx, ry + 45,
        grid_w,
        'center'
    )
end
