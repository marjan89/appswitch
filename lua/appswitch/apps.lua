-- apps.lua - Application discovery and management
-- Handles finding windowless apps and launching them

local M = {}

---Get all running apps without windows
---@param windowed_apps table Set of app names that have windows (keys = app names)
---@return table Array of app names without windows
function M.get_windowless_apps(windowed_apps)
    -- Get running apps from /Applications, ~/Applications, and /System/Applications
    local cmd = [[ps aux | \
        sed -n '/\/Applications\/.*\.app\/Contents\/MacOS/p; /\/System\/Applications\/.*\.app\/Contents\/MacOS/p' | \
        grep -v grep | grep -v Helper | grep -v Extension | \
        sed -E 's|.*/([^/]+)\.app/Contents/MacOS.*|\1|' | \
        sort -u]]

    local output, code = syntropy.shell(cmd)
    if code ~= 0 then
        return {}
    end

    local apps = {}
    for app_name in output:gmatch("[^\n]+") do
        if app_name ~= "" then
            -- Skip if app already has windows
            if not windowed_apps[app_name] then
                -- Skip if it's a menu bar only app
                if not M.is_menu_bar_app(app_name) then
                    table.insert(apps, app_name)
                end
            end
        end
    end

    return apps
end

---Check if an app is menu bar only (LSUIElement set)
---@param app_name string Application name
---@return boolean True if menu bar only app
function M.is_menu_bar_app(app_name)
    -- Escape special characters in app name for shell
    local escaped_name = app_name:gsub("'", "'\\''")

    local cmd = string.format([[
        for dir in /Applications /System/Applications ~/Applications; do
            plist="$dir/%s.app/Contents/Info.plist"
            if [ -f "$plist" ]; then
                defaults read "$dir/%s.app/Contents/Info" LSUIElement 2>/dev/null
                break
            fi
        done
    ]], escaped_name, escaped_name)

    local output, _ = syntropy.shell(cmd)
    return output:match("1") or output:match("YES") or false
end

---Open an application by name
---@param app_name string Application name to open
---@return string output Command output
---@return number code Exit code
function M.open_app(app_name)
    -- Validate input
    if not app_name or app_name == "" then
        return "Error: No app name provided", 1
    end

    -- Escape special characters for shell
    local escaped_name = app_name:gsub('"', '\\"')
    return syntropy.shell(string.format('open -a "%s"', escaped_name))
end

---Generate preview text for an app
---@param app_name string Application name
---@return string Preview text
function M.preview_app(app_name)
    -- Try to find app path using mdfind
    local escaped_name = app_name:gsub("'", "'\\''")
    local cmd = string.format(
        "mdfind \"kMDItemKind == 'Application' && kMDItemDisplayName == '%s'\" 2>/dev/null | head -1",
        escaped_name
    )

    local path, _ = syntropy.shell(cmd)
    path = path:gsub("\n", ""):gsub("^%s*(.-)%s*$", "%1")  -- trim

    if path ~= "" then
        -- Try to get bundle identifier
        local bundle_cmd = string.format(
            "defaults read '%s/Contents/Info' CFBundleIdentifier 2>/dev/null",
            path
        )
        local bundle_id, _ = syntropy.shell(bundle_cmd)
        bundle_id = bundle_id:gsub("\n", ""):gsub("^%s*(.-)%s*$", "%1")

        if bundle_id ~= "" then
            return string.format("App: %s\nPath: %s\nBundle ID: %s", app_name, path, bundle_id)
        else
            return string.format("App: %s\nPath: %s", app_name, path)
        end
    else
        return string.format("App: %s\n(Path not found)", app_name)
    end
end

return M
