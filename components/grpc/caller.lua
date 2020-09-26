GRPC_Caller = {
}

function GRPC_Caller:action()
    self:call("gRPC", "something", nil)
end
