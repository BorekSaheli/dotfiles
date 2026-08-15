local M = {}

-- True if the pane is running Neovim. Accepts both a PaneInformation table
-- (format-tab-title) and a live Pane object (event handlers).
function M.is_nvim(pane)
  local vars = pane.user_vars or (pane.get_user_vars and pane:get_user_vars()) or {}
  if vars.NVIM then
    return true
  end
  local name = pane.foreground_process_name
    or (pane.get_foreground_process_name and pane:get_foreground_process_name())
    or ''
  return name:lower():find('nvim', 1, true) ~= nil
end

return M
