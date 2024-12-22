--!strict
local fs = require("@lune/fs")
local process = require("@lune/process")
local net = require("@lune/net")
local serde = require("@lune/serde")
local datetime = require("@lune/datetime")
local task = require("@lune/task")

-- Load configuration
local function loadConfig(): table
    local defaultConfig = {
        srcDir = "src",
        distDir = "dist",
        webPort = 3000,
        build = {
            name = "MainModule",
            header = {
                enabled = true,
                file = "header.luau"
            },
            rojo = {
                projectFile = "default.project.json"
            },
            wax = {
                minify = false,
                envName = "WaxRuntime"
            }
        },
        web = {
            enabled = true,
            port = 3000,
            routes = {
                bundle = "/"
            }
        }
    }

    if fs.isFile("bundle.config.json") then
        local content = fs.readFile("bundle.config.json")
        local config = serde.decode("json", content)
        -- Merge with defaults
        return setmetatable(config, { __index = defaultConfig })
    end

    return defaultConfig
end

local CONFIG = loadConfig()

-- Ensure directories exist
if not fs.isDir(CONFIG.srcDir) then
    fs.writeDir(CONFIG.srcDir)
end

if not fs.isDir(CONFIG.distDir) then
    fs.writeDir(CONFIG.distDir)
end

-- Get current time string
local function getTimeStr(): string
    local time = os.date("*t")
    return string.format("%02d:%02d:%02d", 
        time.hour or 0,
        time.min or 0,
        time.sec or 0
    )
end

-- Process header template
local function processHeader(): string
    if not CONFIG.build.header.enabled then
        return ""
    end

    if not fs.isFile(CONFIG.build.header.file) then
        print("Warning: Header file not found:", CONFIG.build.header.file)
        return ""
    end

    local header = fs.readFile(CONFIG.build.header.file)
    local timestamp = getTimeStr()
    
    -- Replace placeholders
    header = header:gsub("%%name%%", CONFIG.build.name)
    header = header:gsub("%%timestamp%%", timestamp)
    header = header:gsub("%%minify%%", tostring(CONFIG.build.wax.minify))
    
    return header
end

-- Bundle using Wax
local function bundleWithWax(silent: boolean?)
    print("Bundling with Wax...")
    print("Minification:", CONFIG.build.wax.minify and "enabled" or "disabled")
    
    -- Create default.project.json if it doesn't exist
    if not fs.isFile(CONFIG.build.rojo.projectFile) then
        fs.writeFile(CONFIG.build.rojo.projectFile, serde.encode("json", {
            name = CONFIG.build.name,
            tree = {
                ["$path"] = CONFIG.srcDir
            }
        }, { pretty = true }))
    end

    -- Run Wax through Lune
    local args = {
        "run",
        "lune/wax",
        "bundle",
        "input=" .. CONFIG.build.rojo.projectFile,
        "output=" .. CONFIG.distDir .. "/bundle.luau",
        "minify=" .. tostring(CONFIG.build.wax.minify),
        "env-name=" .. CONFIG.build.wax.envName
    }

    process.spawn("lune", args)

    -- Add header to the bundled file if enabled
    if CONFIG.build.header.enabled then
        local header = processHeader()
        if header ~= "" then
            local bundlePath = CONFIG.distDir .. "/bundle.luau"
            if fs.isFile(bundlePath) then
                local content = fs.readFile(bundlePath)
                fs.writeFile(bundlePath, header .. "\n" .. content)
                print("Added header to bundle")
            end
        end
    end
    
    if not silent then
        print("Bundle updated at " .. getTimeStr())
    end
end

-- Build RBXM using Rojo
local function buildRbxm(silent: boolean?)
    print("Building RBXM with Rojo...")
    local result = process.spawn("rojo", {
        "build",
        "--output",
        CONFIG.distDir .. "/bundle.rbxm"
    })
    return result.ok
end

-- Start web server for bundle visualization
local function startWebServer()
    if not CONFIG.web.enabled then
        print("Web server disabled in config")
        return
    end

    print("Starting web server on port " .. CONFIG.web.port)
    
    local server = net.serve(CONFIG.web.port, function(request)
        if request.path == CONFIG.web.routes.bundle then
            local mainContent = fs.readFile(CONFIG.distDir .. "/bundle.luau")
            local data = {
                bundle = mainContent
            }
            return {
                status = 200,
                headers = {
                    ["Content-Type"] = "application/json"
                },
                body = serde.encode("json", data)
            }
        end
        
        return {
            status = 404,
            headers = {
                ["Content-Type"] = "text/plain"
            },
            body = "Not found"
        }
    end)
    
    print("Web server started at http://localhost:" .. CONFIG.web.port)
    return server
end

-- Watch for changes
local function watch()
    -- Print initial config
    print("Minification:", CONFIG.build.wax.minify and "enabled" or "disabled")

    -- Initial build
    bundleWithWax()
    buildRbxm()
    local server = startWebServer()

    -- Start Go watcher
    print("\nStarting file watcher...")
    
    while true do
        local watcher = process.spawn("go", { "run", "watcher.go" }, {
            stdio = { stdout = process.stdout, stderr = process.stderr }
        })

        -- Wait for watcher to exit (means a change was detected)
        if watcher.code == 0 then
            -- Rebuild on changes
            bundleWithWax(true)
            buildRbxm(true)
        else
            print("Watcher error:", watcher.stderr)
            task.wait(1)
        end
    end
end

-- Main execution
local function main()
    local args = process.args
    if #args > 0 and args[1] == "watch" then
        watch()
    else
        bundleWithWax()
        buildRbxm()
        startWebServer()
        
        print("\nBundle process completed!")
        print("- Bundled output: " .. CONFIG.distDir .. "/bundle.luau")
        print("- RBXM output: " .. CONFIG.distDir .. "/bundle.rbxm")
        print("- Web viewer: http://localhost:" .. CONFIG.web.port)
        print("\nTip: Run 'lune run bundle watch' to start watch mode")
    end
end

main()
