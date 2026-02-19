-- windows.lua - Window management for yabai
-- Handles querying, parsing, and focusing windows

local json = require("json")

local M = {}

---Get all windows from yabai as structured data
---@return table Array of window objects
function M.get_windows()
    local output, code = syntropy.shell("yabai -m query --windows 2>/dev/null")
    if code ~= 0 then
        return {}
    end

    -- Parse JSON
    local success, windows = pcall(json.decode, output)
    if not success or not windows then
        return {}
    end

    return windows
end

---Format window for display in the UI
---@param win table Window object from yabai
---@return string Formatted display string
function M.format_window(win)
    local title = win.title or "Untitled"
    return string.format("%s - %s", win.app, title)
end

---Focus a window by ID using yabai
---@param window_id number Window ID to focus
---@return string output Command output
---@return number code Exit code
function M.focus_window(window_id)
    return syntropy.shell("yabai -m window --focus " .. tostring(window_id))
end

---Generate preview text for a window
---@param win table Window object from yabai
---@return string Preview text
function M.preview_window(win)
    return string.format([[App: %s
Title: %s
Window ID: %s
Space: %s
Display: %s
Visible: %s]],
        win.app or "?",
        win.title or "Untitled",
        tostring(win.id or "?"),
        tostring(win.space or "?"),
        tostring(win.display or "?"),
        tostring(win["is-visible"] or false)
    )
end

---Find window by display string (stateless lookup)
---Re-queries yabai for fresh window list and matches by display string
---@param display string Display string from items() (e.g., "Safari - Github")
---@return table|nil Window object or nil if not found
function M.find_window_by_display(display)
    -- Re-query windows fresh (no cache, Pattern 3: stateless)
    local windows = M.get_windows()

    -- Find matching window by comparing formatted display strings
    for _, win in ipairs(windows) do
        if win.app and win.app ~= "" then
            local win_display = M.format_window(win)
            if win_display == display then
                return win
            end
        end
    end

    return nil
end

return M
