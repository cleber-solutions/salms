AMQP_Exchange = {
    input_type = "amqp.publish"
}

function AMQP_Exchange:action()
    self:call("amqp.topic", "test", nil)
end

function AMQP_Exchange:call_action(call_args)
    self.status = "Distributing..."
    self:call_neighbours("amqp.topic", "topic", call_args)

    -- do NOT wait, since delivery is asynchronous
    -- call_args.waiting = true
end
