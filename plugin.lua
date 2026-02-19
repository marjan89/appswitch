---@type PluginDefinition

-- ============================================================================
-- Plugin Configuration (can be overridden via merge)
-- ============================================================================

local default_config = {}

-- ============================================================================
-- Runtime Config Access Functions
-- ============================================================================

---Get the icons file path from config
---@return string|nil Expanded path to icons file, or nil if not configured
local function get_icons_file()
	-- Access the merged plugin config from globals at runtime
	-- This ensures we get the overridden value if present
	local plugin = appswitch  -- Plugin is stored in globals with its name
	local config = plugin.config or default_config
	if config.icons_file then
		return syntropy.expand_path(config.icons_file)
	end
	return nil
end

---Get the whitelist file path from config
---@return string|nil Expanded path to whitelist file, or nil if not configured
local function get_whitelist_file()
	local plugin = appswitch
	local config = plugin.config or default_config
	if config.whitelist_file then
		return syntropy.expand_path(config.whitelist_file)
	end
	return nil
end

---Get the exclusions file path from config
---@return string|nil Expanded path to exclusions file, or nil if not configured
local function get_exclusions_file()
	local plugin = appswitch
	local config = plugin.config or default_config
	if config.exclusions_file then
		return syntropy.expand_path(config.exclusions_file)
	end
	return nil
end

---Read exclusions from .appswitch_exclusions file
---@return table Array of exclusion strings
local function get_exclusions()
	local path = get_exclusions_file()
	if not path then
		return {}
	end

	local file = io.open(path, "r")
	if not file then
		return {}
	end

	local exclusions = {}
	for line in file:lines() do
		-- Trim whitespace and add non-empty lines
		local trimmed = line:gsub("^%s*(.-)%s*$", "%1")
		if trimmed ~= "" then
			table.insert(exclusions, trimmed)
		end
	end
	file:close()

	return exclusions
end

---Check if an item matches any exclusion pattern
---@param item string Item to check
---@param exclusions table Array of exclusion strings
---@return boolean True if item should be excluded
local function is_excluded(item, exclusions)
	for _, exclusion in ipairs(exclusions) do
		if item == exclusion then
			return true
		end
	end
	return false
end

return {
	metadata = {
		name = "appswitch",
		version = "1.0.0",
		icon = "󰨡", -- Window switcher
		description = "Switch windows and launch apps lightning-fast. Fuzzy search with custom icons. Filter noise. macOS + yabai.",
		platforms = { "macos" },
	},

	config = default_config,

	tasks = {
		open = {
			name = "Open Application",
			description = "Open any installed macOS application",
			mode = "none", -- Single selection, immediate execution
			exit_on_execute = true, -- Exit TUI after opening

			item_sources = {
				apps = {
					tag = "app",

					items = function()
						local appopen_lib = require("appswitch.appopen")
						local apps = appopen_lib.discover_apps()
						local formatted = appopen_lib.format_apps_with_icons(apps)

						return formatted
					end,

					preview = function(item)
						local appopen_lib = require("appswitch.appopen")
						local app_name = appopen_lib.extract_app_name(item)

						-- Re-discover apps to get the path
						local apps = appopen_lib.discover_apps()
						local app_path = apps[app_name]

						if not app_path then
							return "Application not found"
						end

						return appopen_lib.preview_app(app_name, app_path)
					end,

					execute = function(items)
						if not items or #items == 0 then
							return "Error: No items to execute", 1
						end

						local appopen_lib = require("appswitch.appopen")
						local app_name = appopen_lib.extract_app_name(items[1])

						-- Re-discover apps to get the path
						local apps = appopen_lib.discover_apps()
						local app_path = apps[app_name]

						if not app_path then
							return "Error: Application not found", 1
						end

						local output, code = appopen_lib.open_app(app_name, app_path)

						if code ~= 0 then
							return "Failed to open app: " .. output, code
						end

						return "Opened: " .. app_name, 0
					end,
				},
			},
		},

		switch = {
			name = "Switch Window/App",
			description = "Switch to open windows or launch background apps using yabai",
			mode = "none", -- Single selection, immediate execution
			exit_on_execute = true, -- Exit TUI after switching

			item_sources = {
				-- Item Source 1: Windows
				windows = {
					tag = "w",

					items = function()
						-- Load module at runtime
						local windows_lib = require("appswitch.windows")

						local exclusions = get_exclusions()
						local windows = windows_lib.get_windows()

						local items = {}

						for _, win in ipairs(windows) do
							if win.app and win.app ~= "" then
								local display = windows_lib.format_window(win)

								-- Filter out excluded windows
								-- Check both "App - Title" format and just "App" name
								if not is_excluded(display, exclusions) and not is_excluded(win.app, exclusions) then
									table.insert(items, display)
								end
							end
						end

						return items
					end,

					preview = function(item)
						local windows_lib = require("appswitch.windows")
						local win = windows_lib.find_window_by_display(item)
						if not win then
							return "Window not found (may have closed)"
						end

						return windows_lib.preview_window(win)
					end,

					execute = function(items)
						local windows_lib = require("appswitch.windows")
						local win = windows_lib.find_window_by_display(items[1])
						if not win then
							return "Error: Window not found (may have closed)", 1
						end

						local output, code = windows_lib.focus_window(win.id)

						if code ~= 0 then
							return "Failed to focus window: " .. output, code
						end

						return "Focused: " .. items[1], 0
					end,
				},

				-- Item Source 2: Apps without windows
				apps = {
					tag = "a",

					items = function()
						-- Load modules at runtime
						local windows_lib = require("appswitch.windows")
						local apps_lib = require("appswitch.apps")

						local exclusions = get_exclusions()
						local windows = windows_lib.get_windows()

						-- Build set of apps that have windows
						local windowed_apps = {}
						for _, win in ipairs(windows) do
							if win.app then
								windowed_apps[win.app] = true
							end
						end

						-- Get apps without windows
						local apps = apps_lib.get_windowless_apps(windowed_apps)

						-- Filter out excluded apps
						local filtered = {}
						for _, app in ipairs(apps) do
							if not is_excluded(app, exclusions) then
								table.insert(filtered, app)
							end
						end

						return filtered
					end,

					preview = function(item)
						local apps_lib = require("appswitch.apps")
						return apps_lib.preview_app(item)
					end,

					execute = function(items)
						local apps_lib = require("appswitch.apps")

						if not items or #items == 0 then
							return "Error: No items to execute", 1
						end

						local app_name = items[1]
						local output, code = apps_lib.open_app(app_name)

						if code ~= 0 then
							return "Failed to open app: " .. output, code
						end

						return "Opened: " .. app_name, 0
					end,
				},
			},
		},
	},
}
