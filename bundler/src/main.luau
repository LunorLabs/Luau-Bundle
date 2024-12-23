--!strict
-- Example main.luau file
local function hello()
    -- print("Hello from main.luau!")
    return "Hello from bundled Luau!"
end

return {
    hello = hello
}
