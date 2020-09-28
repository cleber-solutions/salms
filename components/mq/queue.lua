MQ_Queue = {
    input_type = "mq.topic",
    topic = "some topic",
    messages_counter = 0,
    in_flight_messages_counter = 0,
    last_id = 0,
    delivery_method = "mq.consume",
    icon = "list.png"
}

function MQ_Queue:call_step(call_args)
    step = call_args.step
    argument = call_args.argument

    -- Ignore other topics:
    if argument ~= self.topic then
        if step == 0 then
            self.status = "Ignored: "..argument
            self:respond(call_args, self.failure_response)
        elseif step == 1 then
            self.status = nil
            return true -- done
        end
        return false
    end

    if step == 0 then
        self.status = "Received: "..argument
    elseif step == 1 then
        self.status = "Persisting"
        self.messages_counter = self.messages_counter + 1
    elseif step == 2 then
        self.status = "Done"
        self:respond(call_args, self.success_response)
    elseif step == 3 then
        self.status = nil
        return true  -- done
    end
end

function MQ_Queue:post_beat()
    if not self.delivery_method then
        return
    end

    -- Always try to deliver messages:
    remaining_messages = self.messages_counter - self.in_flight_messages_counter
    if remaining_messages > 0 then
        self.status = "Delivering"
        message = {
            instances = 0,
            message_id = self.last_id
        }
        sent = self:call_neighbours(self.delivery_method, self.topic, message)
        if sent > 0 then
            message.instances = sent
            self.in_flight_messages_counter = self.in_flight_messages_counter + 1
            self.last_id = self.last_id + 1
        end
    end
end

function MQ_Queue:response_step_one(response_data)
    if response_data.response == response_data.responder.success_response then
        message = response_data.context

        if message.instances > 1 then
            message.instances = message.instances - 1
        else
            self.status = "Delivered!"
            self.messages_counter = self.messages_counter - 1
            self.in_flight_messages_counter = self.in_flight_messages_counter - 1
        end
    end
end

function MQ_Queue:post_draw(rx, ry)
    if self.messages_counter == 0 then
        n = "empty"
    else
        n = self.messages_counter
    end

    love.graphics.printf(
        self.topic..": "..n,
        rx, ry + 60,
        grid_w,
        'center'
    )
end
