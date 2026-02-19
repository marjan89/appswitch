-- ============================================================================
-- Configuration Override Example for appswitch Plugin
-- ============================================================================
--
-- This file demonstrates how to override the default configuration paths
-- for the appswitch plugin using syntropy's deep merge mechanism.
--
-- USAGE:
--   1. Create this file at: ~/.config/syntropy/plugins/appswitch/plugin.lua
--   2. Modify the config paths to your desired locations
--   3. The plugin will automatically use your custom paths at runtime
--
-- The default paths are:
--   - icons_file: ~/.config/syntropy/plugins/appswitch/.appopen_icons
--   - whitelist_file: ~/.config/syntropy/plugins/appswitch/.appopen_white_list
--   - exclusions_file: ~/.config/syntropy/plugins/appswitch/.appswitch_exclusions
--
-- You can override any or all of these paths below.
-- ============================================================================

---@type PluginOverride
return {
	metadata = {
		name = "appswitch",  -- Must match the plugin name
		version = "1.0.0",
	},

	config = {
		-- Override paths to custom locations:
		icons_file = "~/.appswitch/icons.txt",
		whitelist_file = "~/.appswitch/whitelist.txt",
		exclusions_file = "~/.appswitch/exclusions.txt",

		-- Or use the defaults (comment out to use defaults):
		-- icons_file = "~/.config/syntropy/plugins/appswitch/.appopen_icons",
		-- whitelist_file = "~/.config/syntropy/plugins/appswitch/.appopen_white_list",
		-- exclusions_file = "~/.config/syntropy/plugins/appswitch/.appswitch_exclusions",

		-- You can also use relative paths:
		-- icons_file = "./my_custom_icons.txt",  -- Relative to plugin directory
		-- whitelist_file = "./my_whitelist.txt",
		-- exclusions_file = "./my_exclusions.txt",
	},
}

-- ============================================================================
-- File Format Reference:
-- ============================================================================
--
-- ICONS FILE (.appopen_icons):
--   Format: AppName=NerdFontIcon
--   Example:
--     Safari=󰇧
--     Google Chrome=󰊯
--     Terminal=󰆍
--     *=󰀻  # Default icon
--
-- WHITELIST FILE (.appopen_white_list):
--   Format: One app name per line
--   Purpose: CoreServices apps to include in app switcher
--   Example:
--     Finder
--
-- EXCLUSIONS FILE (.appswitch_exclusions):
--   Format: One app name or window name per line
--   Purpose: Apps/windows to exclude from window switcher
--   Example:
--     AdGuard for Safari
--     kitty - appswitch
--     Karabiner-VirtualHIDDevice-Daemon
-- ============================================================================
