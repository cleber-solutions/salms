local schema = {}

components = require("components")

require("components/mq/consumer")
require("components/mq/exchange")
require("components/mq/queue")
require("components/rpc/caller")
require("components/rpc/service")
require("components/db/table")


function schema.init()

    -- line 0:
    create_object(RPC_Caller, "RPC Caller", 0, 0)

    rpc_service = create_object(RPC_Service, "RPC Service", 1, 0)
    rpc_service.call_steps = {
        {"mq.publish", "rpc.called", "Sending message..."},
        {"db", "persist", "Persisting..."},
        {"mq.publish", "data.persisted", "Sending second message..."}
    }
    create_object(MQ_Exchange, "MQ Exchange", 2, 0)
    q1 = create_object(MQ_Queue, "MQ Queue 1", 3, 0)
    q1.topic = "rpc.called"
    create_object(MQ_Consumer, "MQ Consumer 1", 4, 0)

    -- line -1:
    create_object(DBTable, "Database", 1, -1)

    -- line 1:
    q2 = create_object(MQ_Queue, "MQ Queue 2", 2, 1)
    q2.topic = "data.persisted"

    -- line 2:
    create_object(MQ_Consumer, "MQ Consumer 2", 2, 2)

    components.load_neighbourhood()
end

function create_object(base, name, x, y)
    local object = Component:create(base, name, x, y)
    components.add(object)
    return object
end

return schema
