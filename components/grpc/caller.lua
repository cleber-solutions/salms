GRPC_Caller = {
}

function GRPC_Caller:action()
    self:call("gRPC", "something", nil)
end

function GRPC_Caller:beat()
    for idx, response_data in ipairs(self.response_list) do
        response_data["step"] = response_data["step"] + 1
        step = response_data["step"]

        if step == 0 then
            c["status"] = "Response: "..response_data["response"]
        elseif step == 1 then
            c["status"] = "Done"
        elseif step == 2 then
            c["status"] = nil
            table.remove(c["response_list"], idx)
            -- TODO: deactivate when resonse_list LENGTH is zero.
            c["active"] = false
        end
    end
end
