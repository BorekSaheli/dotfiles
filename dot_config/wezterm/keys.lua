local wezterm = require 'wezterm'
local act = wezterm.action
local M = {}

-- h/j/k/l everywhere. CTRL|SHIFT = move focus, CTRL|SHIFT|ALT = resize.
local dirs = { h = 'Left', j = 'Down', k = 'Up', l = 'Right' }

function M.apply(config)
  local keys = {
    -- Panes
    { key = 'r', mods = 'CTRL|SHIFT|ALT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
    { key = 'b', mods = 'CTRL|SHIFT|ALT', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
    { key = 't', mods = 'CTRL|SHIFT|ALT', action = act.SplitPane { direction = 'Down', size = { Percent = 25 } } },
    { key = 'q', mods = 'CTRL|SHIFT', action = act.CloseCurrentPane { confirm = false } },
  }

  for key, dir in pairs(dirs) do
    table.insert(keys, { key = key, mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection(dir) })
    table.insert(keys, { key = key, mods = 'CTRL|SHIFT|ALT', action = act.AdjustPaneSize { dir, 2 } })
  end

  config.keys = keys
end

return M
