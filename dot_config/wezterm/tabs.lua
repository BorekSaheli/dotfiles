local wezterm = require 'wezterm'
local util = require 'util'
local M = {}

function M.apply(_)
  -- "1: nvim" / "2: fish" — nvim detected via user vars / process, not the
  -- noisy child-process titles it sets.
  wezterm.on('format-tab-title', function(tab)
    local pane = tab.active_pane
    local name = util.is_nvim(pane) and 'nvim' or (pane.title or 'shell'):gsub('%.exe$', '')
    return ' ' .. (tab.tab_index + 1) .. ': ' .. name .. ' '
  end)
end

return M
