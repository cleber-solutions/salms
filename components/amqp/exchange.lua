AMQP_Exchange = {
    input_type = "amqp.publish"
}

function AMQP_Exchange:call_action_not_implemented()
    self.status = "Distributing..."
    self:call_neighbours("db", "persist", call_args)
end
