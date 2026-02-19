# appswitch Plugin

Interactive window/app switcher for macOS using yabai.

## Features

- **Window Switching**: Switch between open windows with live previews
- **App Launching**: Open any installed macOS application with fuzzy search
- **Custom Icons**: NerdFont icons for applications
- **Filtering**: Exclude specific windows and apps from the switcher
- **CoreServices Whitelist**: Control which system apps appear in the launcher

## Installation

Add the following to your syntropy configuration file (`~/.config/syntropy/config.toml`):

```toml
[plugins.appswitch]
git = "https://github.com/marjan89/appswitch.git"
tag = "v1.0.0"
```

## Tasks

### `appswitch:switch`
Switch to open windows or launch background apps using yabai.

- Lists all open windows with app name and title
- Shows background apps without windows
- Filters out excluded windows/apps
- Focuses selected window or opens selected app

### `appswitch:open`
Open any installed macOS application.

- Discovers apps from `/Applications`, `~/Applications`, and `/System/Applications`
- Applies CoreServices whitelist filter
- Shows custom icons for each app
- Opens selected application

## Configuration

The plugin supports runtime configuration via syntropy's override mechanism. Create an override file at:

```
~/.config/syntropy/plugins/appswitch/plugin.lua
```

### Configuration Options

```lua
---@type PluginOverride
return {
	metadata = {
		name = "appswitch",
	},

	config = {
		icons_file = "~/.config/syntropy/plugins/appswitch/.appopen_icons",
		whitelist_file = "~/.config/syntropy/plugins/appswitch/.appopen_white_list",
		exclusions_file = "~/.config/syntropy/plugins/appswitch/.appswitch_exclusions",
	},
}
```

### Configuration Files

#### Icons File (`.appopen_icons`)
Maps application names to NerdFont icons.

**Format**: `AppName=Icon`

**Example**:
```
Safari=󰇧
Google Chrome=󰊯
Terminal=󰆍
Visual Studio Code=󰨞
*=󰀻  # Default icon for unmapped apps
```

#### Whitelist File (`.appopen_white_list`)
CoreServices apps to include in the app launcher. Only apps from `/System/Library/CoreServices` listed here will appear.

**Format**: One app name per line

**Example**:
```
Finder
```

#### Exclusions File (`.appswitch_exclusions`)
Windows and apps to exclude from the window switcher.

**Format**: One app name or window title per line

**Example**:
```
AdGuard for Safari
kitty - appswitch
Karabiner-VirtualHIDDevice-Daemon
```

## Directory Structure

### Base Plugin (Code)
```
~/.local/share/syntropy/plugins/appswitch/
├── lua/
│   ├── appswitch/
│   │   ├── appopen.lua    # App discovery and launching
│   │   ├── apps.lua       # Background apps without windows
│   │   └── windows.lua    # Window management
│   └── json.lua           # JSON library (rxi/json.lua)
├── plugin.lua             # Main plugin definition
├── config_example.lua     # Example configuration override
└── README.md              # This file
```

### User Override (Configuration)
```
~/.config/syntropy/plugins/appswitch/
├── plugin.lua             # Configuration override
├── .appopen_icons         # Icon mappings
├── .appopen_white_list    # CoreServices whitelist
└── .appswitch_exclusions  # Window/app exclusions
```

## Dependencies

- **macOS**: Required
- **yabai**: Required for window management
  - Install: `brew install koekeishiya/formulae/yabai`
  - See: https://github.com/koekeishiya/yabai

## Usage Examples

### Launch the window switcher
```bash
syntropy appswitch:switch
```

### Launch the app opener
```bash
syntropy appswitch:open
```

### Custom configuration location
```lua
-- ~/.config/syntropy/plugins/appswitch/plugin.lua
return {
	metadata = { name = "appswitch" },
	config = {
		icons_file = "~/my-config/app-icons.txt",
		whitelist_file = "~/my-config/whitelist.txt",
		exclusions_file = "~/my-config/exclusions.txt",
	},
}
```

## Third-Party Libraries

This plugin includes the following third-party library:

- **json.lua** (v0.1.2) by rxi
  A lightweight JSON library for Lua
  Copyright (c) 2020 rxi
  Licensed under the MIT License
  https://github.com/rxi/json.lua

## License

MIT License - see [LICENSE](LICENSE) file for details.
