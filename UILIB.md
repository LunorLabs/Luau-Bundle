# 🎨 UI Library Guide

This guide shows how to create a modern UI library similar to Fluent UI.

## Basic Structure

```lua
-- src/modules/ui.luau
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local Library = {
    Theme = {
        Background = Color3.fromRGB(32, 32, 32),
        Foreground = Color3.fromRGB(255, 255, 255),
        Accent = Color3.fromRGB(0, 120, 215),
        Success = Color3.fromRGB(40, 200, 120),
        Error = Color3.fromRGB(200, 40, 40)
    }
}

-- Window class
local Window = {}
Window.__index = Window

function Library.CreateWindow(config)
    config = config or {}
    
    local window = setmetatable({
        Title = config.Title or "UI Library",
        Visible = true,
        Tabs = {},
        CurrentTab = nil
    }, Window)
    
    window:Create()
    return window
end

function Window:Create()
    -- Create ScreenGui
    self.Gui = Instance.new("ScreenGui")
    self.Gui.Name = "UILibrary"
    self.Gui.Parent = CoreGui
    
    -- Main frame
    self.Main = Instance.new("Frame")
    self.Main.Name = "Main"
    self.Main.Size = UDim2.new(0, 500, 0, 350)
    self.Main.Position = UDim2.new(0.5, -250, 0.5, -175)
    self.Main.BackgroundColor3 = Library.Theme.Background
    self.Main.Parent = self.Gui
    
    -- Make draggable
    self:MakeDraggable()
    
    -- Title bar
    self.TitleBar = Instance.new("Frame")
    self.TitleBar.Name = "TitleBar"
    self.TitleBar.Size = UDim2.new(1, 0, 0, 30)
    self.TitleBar.BackgroundColor3 = Library.Theme.Accent
    self.TitleBar.Parent = self.Main
    
    -- Title text
    local title = Instance.new("TextLabel")
    title.Text = self.Title
    title.Size = UDim2.new(1, -10, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.TextColor3 = Library.Theme.Foreground
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = self.TitleBar
end

function Window:MakeDraggable()
    local dragging = false
    local dragInput
    local dragStart
    local startPos

    self.Main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = self.Main.Position
        end
    end)

    self.Main.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            self.Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- Tab class
local Tab = {}
Tab.__index = Tab

function Window:AddTab(name)
    local tab = setmetatable({
        Name = name,
        Window = self,
        Elements = {}
    }, Tab)
    
    tab:Create()
    table.insert(self.Tabs, tab)
    
    if not self.CurrentTab then
        self.CurrentTab = tab
        tab:Show()
    end
    
    return tab
end

function Tab:Create()
    -- Tab button
    self.Button = Instance.new("TextButton")
    self.Button.Name = self.Name
    self.Button.Size = UDim2.new(0, 100, 0, 30)
    self.Button.Position = UDim2.new(0, #self.Window.Tabs * 100, 0, 30)
    self.Button.BackgroundColor3 = Library.Theme.Background
    self.Button.TextColor3 = Library.Theme.Foreground
    self.Button.Text = self.Name
    self.Button.Parent = self.Window.Main
    
    -- Tab content
    self.Content = Instance.new("Frame")
    self.Content.Name = "Content"
    self.Content.Size = UDim2.new(1, 0, 1, -60)
    self.Content.Position = UDim2.new(0, 0, 0, 60)
    self.Content.BackgroundTransparency = 1
    self.Content.Visible = false
    self.Content.Parent = self.Window.Main
    
    self.Button.MouseButton1Click:Connect(function()
        self:Show()
    end)
end

function Tab:Show()
    if self.Window.CurrentTab then
        self.Window.CurrentTab.Content.Visible = false
    end
    self.Content.Visible = true
    self.Window.CurrentTab = self
end

-- UI Elements
function Tab:AddButton(text, callback)
    local button = Instance.new("TextButton")
    button.Name = text
    button.Size = UDim2.new(0, 200, 0, 30)
    button.Position = UDim2.new(0, 10, 0, 10 + #self.Elements * 40)
    button.BackgroundColor3 = Library.Theme.Accent
    button.TextColor3 = Library.Theme.Foreground
    button.Text = text
    button.Parent = self.Content
    
    button.MouseButton1Click:Connect(callback)
    table.insert(self.Elements, button)
    return button
end

function Tab:AddToggle(text, default, callback)
    local toggle = Instance.new("Frame")
    toggle.Name = text
    toggle.Size = UDim2.new(0, 200, 0, 30)
    toggle.Position = UDim2.new(0, 10, 0, 10 + #self.Elements * 40)
    toggle.BackgroundTransparency = 1
    toggle.Parent = self.Content
    
    local label = Instance.new("TextLabel")
    label.Text = text
    label.Size = UDim2.new(0, 160, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Library.Theme.Foreground
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = toggle
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 30, 0, 30)
    button.Position = UDim2.new(1, -30, 0, 0)
    button.BackgroundColor3 = default and Library.Theme.Success or Library.Theme.Error
    button.Text = ""
    button.Parent = toggle
    
    local enabled = default
    button.MouseButton1Click:Connect(function()
        enabled = not enabled
        button.BackgroundColor3 = enabled and Library.Theme.Success or Library.Theme.Error
        callback(enabled)
    end)
    
    table.insert(self.Elements, toggle)
    return toggle
end

return Library
```

## Usage Example

```lua
local UI = require("modules/ui")

-- Create window
local window = UI.CreateWindow({
    Title = "My Script"
})

-- Add tabs
local mainTab = window:AddTab("Main")
local settingsTab = window:AddTab("Settings")

-- Add elements
mainTab:AddButton("Click Me", function()
    print("Button clicked!")
end)

mainTab:AddToggle("Auto Farm", false, function(enabled)
    if enabled then
        print("Auto farm enabled")
    else
        print("Auto farm disabled")
    end
end)
```

## Features

1. Modern, clean design
2. Draggable window
3. Tab system
4. Buttons and toggles
5. Customizable theme
6. Smooth animations (can be added with TweenService)

## Customization

You can customize the UI by modifying the Theme table:

```lua
Library.Theme = {
    Background = Color3.fromRGB(32, 32, 32),  -- Dark background
    Foreground = Color3.fromRGB(255, 255, 255),  -- White text
    Accent = Color3.fromRGB(0, 120, 215),  -- Blue accent
    Success = Color3.fromRGB(40, 200, 120),  -- Green for enabled toggles
    Error = Color3.fromRGB(200, 40, 40)  -- Red for disabled toggles
}
```
