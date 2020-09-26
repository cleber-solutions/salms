local schema = {}

components = require("components")

require("components/amqp/exchange")
require("components/amqp/queue")
require("components/grpc/caller")
require("components/grpc/service")
require("components/dynamodb/table")


function schema.init()
    create_object(GRPC_Caller, "gRPC Caller", 0, 0)
    create_object(GRPC_Service, "gRPC Service", 0, 1)
    create_object(DynamoTable, "DynamoDB Table", 1, 1)
    create_object(AMQP_Exchange, "AMQP Exchange", 0, 2)
    create_object(AMQP_Queue, "AMQP Queue", 1, 2)
end

function create_object(base, name, x, y)
    local object = Component:create(base, name, x, y)
    components.add(x, y, object)
    return object
end

return schema
