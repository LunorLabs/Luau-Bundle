--!strict
local fs = require("@lune/fs")
local process = require("@lune/process")
local task = require("@lune/task")

type FileWatcher = {
    start: (onFileChange: () -> ()) -> (),
    stop: () -> ()
}

type WatcherConfig = {
    srcDir: string,
    patterns: {string}
}

type FileState = { [string]: { modifiedAt: string } }

-- Create a new watcher instance
local function createWatcher(config: WatcherConfig): FileWatcher
    local self = {
        running = false
    }

    -- Function to check if file matches pattern
    local function isLuaFile(path: string): boolean
        return path:sub(-4) == ".lua" or path:sub(-5) == ".luau"
    end

    -- Function to get file state
    local function getFileStates(): FileState
        local states: FileState = {}

        -- Check if directory exists
        if not fs.isDir(config.srcDir) then
            error("Source directory '" .. config.srcDir .. "' does not exist!")
        end

        -- Get all files in directory recursively
        local function scanDir(dir: string)
            for _, entry in ipairs(fs.readDir(dir)) do
                local fullPath = dir .. "/" .. entry
                if fs.isFile(fullPath) then
                    if isLuaFile(fullPath) then
                        local metadata = fs.metadata(fullPath)
                        states[fullPath] = {
                            modifiedAt = tostring(metadata.modifiedAt)
                        }
                    end
                elseif fs.isDir(fullPath) then
                    scanDir(fullPath)
                end
            end
        end

        scanDir(config.srcDir)
        return states
    end

    -- Function to get relative path
    local function getRelativePath(path: string): string
        local prefix = config.srcDir .. "/"
        if path:sub(1, #prefix) == prefix then
            return path:sub(#prefix + 1)
        end
        return path
    end

    -- Function to check if files have changed
    local function hasChanges(oldStates: FileState, newStates: FileState): boolean
        -- Check for new or modified files
        for path, newState in pairs(newStates) do
            local oldState = oldStates[path]
            if not oldState or oldState.modifiedAt ~= newState.modifiedAt then
                print("Changed file:", getRelativePath(path))
                return true
            end
        end

        -- Check for deleted files
        for path in pairs(oldStates) do
            if not newStates[path] then
                print("Deleted file:", getRelativePath(path))
                return true
            end
        end

        return false
    end

    -- Create delay
    local function delay()
        task.wait(1)
    end

    -- Start watching for changes
    local function start(onFileChange: () -> ())
        if self.running then
            return
        end

        self.running = true
        print("Starting file watcher...")
        print("Watching for changes in " .. config.srcDir)
        print("Tracking .lua and .luau files")

        -- Track file states
        local lastStates = {}

        -- Watch loop
        task.spawn(function()
            while self.running do
                local currentStates = getFileStates()
                
                -- If files were modified
                if hasChanges(lastStates, currentStates) then
                    if next(lastStates) ~= nil then
                        print("\nChanges detected, rebuilding...")
                        onFileChange()
                    end
                    lastStates = currentStates
                end

                delay()
            end
        end)
    end

    -- Stop watching
    local function stop()
        self.running = false
        print("Stopping file watcher...")
    end

    return {
        start = start,
        stop = stop
    }
end

return {
    createWatcher = createWatcher
}
