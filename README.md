# salms: Software Architecture Live Diagrams

**FEEL FREE TO CONTRIBUTE TO THIS PROJECT**

![GIF demonstranting the results](https://raw.githubusercontent.com/cleber-solutions/salms/master/img/grpc-dynamo-and-amqp.gif)

As a Software Architect I'm a big fan of
**sequence diagrams**. I like the way they convey so much
information in a orderly manner. But it can be quite a
challenge for most normal people and even for a lot of
Software Engineers to understand the information flux and
what each component is supposed to do using such diagrams.

So I thought it would be nice to put on screen the
architectural pattern more or less in the way it shows
itself in my own head. I would like to be able to draw a
component and be able to easily show basic things like:

* It is called by this other component;
* It should validate data;
* then save on database;
* then send a message to other components;
* and only then respond as a successful transaction.

## Running

1. You must have [Löve](https://love2d.org/) installed.
1. Inside the repo root directory, run `love .`.

## How this system works

### Beats and steps

Since it's very important to understand the behavior of each
component in a timely manner, the whole system is based on
**time beats** or *beats*. You know, as if someone was
beating a drum to mark the timing of each thing.

Common actions like responding to a call or processing a
response from some neighbour always has a `step` by which
you can guide yourself.

For instance: to process a call response, your component
would:

1. Change it's status to "Received "..response_data.response
1. Maybe do something else with the response
1. Clear it's status

(The `status` is shown on screen when set.)

    Right now the beats are time-based, but
    I intend to allow users to
    advance beats "by hand".

### Actions

You can trigger the **first component** action by pressing
`x`, or any other component by clicking with the right
mouse button (button 3).

(But remember: components are not forced to implement any
action.)

### Calls

Each component has an `input_type` that is used to find
which neighbour is the one that provides such a method.

### Grid and Neighbourhood

While drawing components by hand I realized most of the
time I was using a imaginary grid to lay out each box, so
*salms* uses the same approach. I would **hate** to have
to draw connections, so you can follow a simple rule:
**every neighbour is connected**. If you don't want two
components to be connected, simply put them apart of
each other.

## How to define components

I was thinking about some way to define components almost
like you would in PlantUML, where there is a "source code"
that generates a PNG file with the diagrams.

This language would need a lot of flow control
capabilities, so, in the end, I opted for using a
programming language simple enough, fast enough and very
portable: **Lua**.

You see, trying to define everything only with descriptions
would lead to a descriptive language with weird flow
control structures. So I found it way better to use a
full-fledged programming language and make everything
easy enough so that most of the time you can be very, very
descriptive, while retaining the power to create more
complex things if you need to.

### Examples

```lua
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
```

I chose a kind of object-oriented style, so all components
should be instantiated using `components.add(x, y, class)`.
"class", in this case, would be `GRPC_Service`.

You'll find more components inside the `components` directory.

## How can you help

* Using it.
* Reporting bugs.
* Writing about it.
* **Writing new components**
* Helping to improve the code, specially to make it
  easier to use for other Architects. (Check `TODO.md`
  file.)
