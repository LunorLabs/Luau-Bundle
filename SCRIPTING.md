# 🚀 Scripting Guide

This guide will help you create scripts using the Luau Bundle system.

## Directory Structure

```
src/
  ├── modules/         # Your reusable modules
  │   ├── ui.luau     # UI Library
  │   └── utils.luau  # Utility functions
  ├── games/          # Game-specific scripts
  │   ├── game1.luau
  │   └── game2.luau
  └── init.luau       # Main entry point
```

## Creating a Basic Script

1. Create your main script in `src/init.luau`:

```lua
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Import your modules
local UI = require("modules/ui")

-- Create window
local window = UI.CreateWindow({
    Title = "My Script",
    Theme = "Dark"
})

-- Add tabs
local mainTab = window:AddTab("Main")
local settingsTab = window:AddTab("Settings")

-- Add buttons and toggles
mainTab:AddButton("Click Me", function()
    print("Button clicked!")
end)

mainTab:AddToggle("Auto Farm", false, function(enabled)
    if enabled then
        -- Start auto farm
    else
        -- Stop auto farm
    end
end)

-- Settings
settingsTab:AddKeybind("Toggle UI", "RightControl", function()
    window:Toggle()
end)
```

## Best Practices

1. **Modularity**: Split your code into reusable modules
2. **Error Handling**: Use pcall for risky operations
3. **Performance**: Cache services and frequently used values
4. **Security**: Avoid exposing sensitive information

## Example Game Script

Here's an example for a specific game:

```lua
-- src/games/example.luau
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

return {
    Name = "Example Game",
    GameId = 123456789,
    Init = function(ui)
        local window = ui.CreateWindow({
            Title = "Example Game"
        })
        
        local mainTab = window:AddTab("Main")
        
        -- Add features
        mainTab:AddToggle("Auto Collect", false, function(enabled)
            -- Implementation
        end)
        
        mainTab:AddButton("Teleport to Shop", function()
            -- Implementation
        end)
    end
}
```

## Loading Multiple Games

```lua
-- src/init.luau
local UI = require("modules/ui")
local games = {
    require("games/game1"),
    require("games/game2")
}

local function loadGameScript()
    for _, game in games do
        if game.GameId == game.PlaceId then
            game.Init(UI)
            break
        end
    end
end

loadGameScript()
```
