RPC_Caller = {
    output_type = "RPC",
    default_argument = "something",
    icon = "remote.png"
}

function RPC_Caller:action()
    self:call(self.output_type, self.default_argument, nil)
end
