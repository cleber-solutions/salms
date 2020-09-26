GRPC_Service = {
    input_type = "gRPC"
}

function GRPC_Service:call_action(call_args)
    self.status = "Persisting..."
    self:call_neighbours("db", "persist", call_args)
    call_args.waiting = true
end

function Component:response_step_one(response_data)
    if response_data.responder.input_type == "db" then
        -- Saved on database, now send message to other components:
        self.status = "Sending message..."
        self:call_neighbours("amqp.publish", "topic", {
            original_context = response_data.context
        })

    elseif response_data.responder.input_type == "amqp.publish" then
        self.status = "Response: "..response_data.response
        response_data.context.original_context.waiting = false
    end
end
