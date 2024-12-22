# [LunorLabs Team] Luau Package Bundler

🚀 Simple package bundler for Luau using Wax and Rojo with minification support

## Features

- Bundle Luau files into a single file
- Build RBXM files using Rojo
- Web interface for visualization
- File watching with Go (requires Go installation)
- Minification support

## Requirements

- [Lune](https://lune-org.github.io/docs)
- [Rojo](https://rojo.space/)
- [Go](https://go.dev/) (for file watching)

## Installation

### Automatic Installation (Windows)

1. Download `install.cmd` from the [latest release](https://github.com/LunorLabs/Luau-Bundlereleases/latest)
2. Run `install.cmd` as administrator
3. Restart your terminal

The script will automatically install:
- Go
- Lune
- Rojo (via Aftman)

### Manual Installation

If you prefer to install manually:
1. Install Go from https://go.dev/dl/
2. Install Lune from https://lune-org.github.io/docs
3. Install Rojo from https://rojo.space/

## Usage

### Basic Bundle

```bash
lune run bundle
```

This will:
1. Bundle your Luau files from `src` directory
2. Generate an RBXM file
3. Output files to `dist` directory

### Watch Mode

```bash
lune run bundle watch
```

This will:
1. Run initial bundle
2. Start web server at http://localhost:3000
3. Watch for file changes and rebuild automatically

## Configuration

Edit `bundle.config.json` to configure:
- Source directory
- Output directory
- Output filename
- Minification

```json
{
    "srcDir": "src",
    "distDir": "dist",
    "build": {
        "name": "MainModule",
        "header": {
            "enabled": true,
            "file": "header.luau"
        },
        "rojo": {
            "projectFile": "default.project.json"
        },
        "wax": {
            "minify": false,
            "envName": "WaxRuntime"
        }
    },
    "web": {
        "enabled": true,
        "port": 3000,
        "routes": {
            "bundle": "/"
        }
    }
}
```

### Options
- `srcDir`: Source directory for Luau files
- `distDir`: Output directory for bundled files
- `build.name`: Name of the bundled module
- `build.header.enabled`: Enable/disable header comments in bundle
- `build.header.file`: Path to header template file
- `build.wax.minify`: Enable/disable code minification
- `build.wax.envName`: Wax environment name
- `web.enabled`: Enable/disable web interface
- `web.port`: Web server port
- `web.routes`: Custom route paths

### Header Template
Create a `header.luau` file to customize the bundle header. Available placeholders:
- `%name%`: Bundle name from config
- `%timestamp%`: Build timestamp
- `%minify%`: Minification status

Example header.luau:
```lua
--[[
    Generated with Luau Package Bundler
    https://github.com/yourusername/bundler-package

    Bundle Name: %name%
    Created At: %timestamp%
    Minified: %minify%
]]
```

## Using with Script Loader

This package bundler can be used effectively with [HoyoGey/Script](https://github.com/HoyoGey/Script) loader:

1. Bundle your Luau script using this bundler:
```bash
lune run bundle
```

2. The bundled output will be in the `dist` directory, which is compatible with the Script loader's format.

3. You can use the bundled script with Script loader by:
   - Using the Game/Place ID functionality in Script loader
   - Loading your bundled script through the loader's interface

Note: Make sure your bundled script follows Script loader's requirements for automatic loading.

## Contributing

**If you know how to make a Luau watcher, please make a pull request with the fix.**

Currently, the file watcher is implemented in Go due to limitations with Luau's file watching capabilities. We'd love to have a native Luau implementation!

## License

MIT License - See LICENSE file for details
