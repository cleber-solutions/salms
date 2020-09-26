function create_object(class)
    local object = {}
    class.__index = class
    setmetatable(object, class)
    return object
end

t = {}
function t:action()
    print("base action")
end

MyTable = {}
function MyTable:action()
    print("MyTable action!")
end

t.action()
MyTable:action()

my_table = create_object(MyTable)
my_table:action()
