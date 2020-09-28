MQ_Exchange = {
    input_type = "mq.publish",
    output_type = "mq.topic",
    default_argument = "some topic",
    icon = "fast-forward.png"
}

function MQ_Exchange:action()
    self:call(self.output_type, self.default_argument, nil)
end

function MQ_Exchange:call_action(call_args)
    self.status = "Distributing..."
    self:call_neighbours(self.output_type, call_args.argument, call_args)
    self:respond(call_args, self.success_response)
    return true -- done
end

function MQ_Exchange:response_step_one(response_data)
    if response_data.response == response_data.responder.success_response then
        self.status = "Delivered!"
    else
        self.status = "Ignored"
    end
end
