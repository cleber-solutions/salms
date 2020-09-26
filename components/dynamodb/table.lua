DynamoTable = {
    input_type = "db"
}

function DynamoTable:call_action(call_args)
    self.status = "Done"
end
