---@class AppopenLib
local M = {}

-- ============================================================================
-- Configuration Access
-- ============================================================================

local default_config = {}

---Get the icons file path from config
---@return string|nil Expanded path to icons file, or nil if not configured
local function get_icons_file()
	-- Access the merged plugin config from globals at runtime
	local plugin = appswitch
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

---Load icon mappings from .appopen_icons file
---@return table<string, string> Map of app name to icon
local function load_icon_mappings()
	local icon_file = get_icons_file()
	local mappings = {}
	local default_icon = "◍"

	if not icon_file then
		mappings["*"] = default_icon
		return mappings
	end

	local file = io.open(icon_file, "r")
	if not file then
		mappings["*"] = default_icon
		return mappings
	end

	for line in file:lines() do
		-- Skip comments and empty lines
		local trimmed = line:gsub("^%s*(.-)%s*$", "%1")
		if trimmed ~= "" and not trimmed:match("^#") then
			-- Parse AppName=Icon format
			local app_name, icon = trimmed:match("^(.+)=(.+)$")
			if app_name and icon then
				mappings[app_name] = icon
			end
		end
	end
	file:close()

	-- Set default icon
	mappings["*"] = default_icon

	return mappings
end

---Get icon for an app name
---@param app_name string Name of the application
---@param mappings table<string, string> Icon mappings
---@return string Icon for the app
local function get_icon(app_name, mappings)
	return mappings[app_name] or mappings["*"] or "◍"
end

---Load whitelist from .appopen_white_list file
---@return table<string, boolean> Set of whitelisted app names (keys = app names)
local function load_whitelist()
	local whitelist_file = get_whitelist_file()
	local whitelist = {}

	if not whitelist_file then
		return whitelist
	end

	local file = io.open(whitelist_file, "r")
	if not file then
		return whitelist
	end

	for line in file:lines() do
		-- Skip comments and empty lines
		local trimmed = line:gsub("^%s*(.-)%s*$", "%1")
		if trimmed ~= "" and not trimmed:match("^#") then
			whitelist[trimmed] = true
		end
	end
	file:close()

	return whitelist
end

---Discover all .app bundles on the system
---@return table<string, string> Map of app name to full path
function M.discover_apps()
	-- Load whitelist for CoreServices apps
	local whitelist = load_whitelist()

	-- Find all .app bundles in standard locations
	local find_cmd = [[find -L /System/Applications /System/Library/CoreServices /Applications ~/Applications -maxdepth 3 -name "*.app" -type d 2>/dev/null | awk '{
		path = $0
		sub(/.*\//, "", $0)
		sub(/\.app$/, "", $0)
		print path "|" $0
	}' | sort -t'|' -k2 -u]]

	local handle = io.popen(find_cmd)
	if not handle then
		return {}
	end

	local apps = {}
	for line in handle:lines() do
		local path, name = line:match("^(.+)|(.+)$")
		if path and name then
			-- Check if this is a CoreServices app
			local is_core_services = path:match("^/System/Library/CoreServices/")

			-- If it's a CoreServices app, only include if whitelisted
			if is_core_services then
				if whitelist[name] then
					apps[name] = path
				end
			else
				-- Include all non-CoreServices apps
				apps[name] = path
			end
		end
	end
	handle:close()

	return apps
end

---Format app list with icons for display
---@param apps table<string, string> Map of app name to path
---@return table Array of formatted items (icon + name)
function M.format_apps_with_icons(apps)
	local icon_mappings = load_icon_mappings()
	local formatted = {}

	for name, _ in pairs(apps) do
		local icon = get_icon(name, icon_mappings)
		table.insert(formatted, string.format("%s  %s", icon, name))
	end

	-- Sort alphabetically
	table.sort(formatted)

	return formatted
end

---Extract app name from formatted display string
---@param display_string string Formatted string with icon
---@return string App name without icon
function M.extract_app_name(display_string)
	-- Remove icon prefix (everything before first "  " - two spaces)
	local name = display_string:match("^[^ ]*  (.+)$")
	return name or display_string
end

---Open an application
---@param app_name string Name of the application
---@param app_path string Full path to the .app bundle
---@return string output Command output
---@return number exit_code Exit code (0 on success)
function M.open_app(app_name, app_path)
	local cmd
	-- Special handling for kitty - force new instance
	if app_name == "kitty" then
		cmd = string.format("open -n '%s' 2>&1", app_path:gsub("'", "'\\''"))
	else
		cmd = string.format("open '%s' 2>&1", app_path:gsub("'", "'\\''"))
	end

	local handle = io.popen(cmd)
	if not handle then
		return "Failed to execute open command", 1
	end

	local output = handle:read("*a")
	local success, _, code = handle:close()
	local exit_code = code or (success and 0 or 1)

	return output, exit_code
end

---Preview app information
---@param app_name string Name of the application
---@param app_path string Full path to the .app bundle
---@return string Preview text
function M.preview_app(app_name, app_path)
	local icon_mappings = load_icon_mappings()
	local icon = get_icon(app_name, icon_mappings)

	local lines = {
		string.format("%s  %s", icon, app_name),
		"",
		"Path:",
		"  " .. app_path,
		"",
		"Action:",
		"  Open application",
	}

	-- Add special note for kitty
	if app_name == "kitty" then
		table.insert(lines, "")
		table.insert(lines, "Note: Will open new instance with 'open -n'")
	end

	return table.concat(lines, "\n")
end

return M
