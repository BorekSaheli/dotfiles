local wezterm = require 'wezterm'

local M = {}

-- Check if nvim is in the process tree (including parent processes)
local function is_nvim_process(pane)
  -- Check foreground process
  local fg_info = pane:get_foreground_process_info()
  if fg_info and fg_info.name then
    local fg_name = fg_info.name:lower()
    if fg_name:find('nvim') or fg_name:find('vim') then
      return true
    end
  end

  -- Check user vars set by shell integration
  local user_vars = pane:get_user_vars()
  if user_vars.NVIM then
    return true
  end

  -- Check the process tree (get_foreground_process_name includes parent check)
  local process_name = pane:get_foreground_process_name()
  if process_name then
    local name = process_name:lower()
    if name:find('nvim') or name:find('vim') then
      return true
    end
  end

  return false
end

-- Find the active nvim pane in the current window
local function find_nvim_pane(window)
  local tab = window:active_tab()
  if not tab then
    return nil
  end

  -- First, check the active pane
  local active_pane = tab:active_pane()
  if active_pane then
    if is_nvim_process(active_pane) then
      return active_pane
    end
  end

  -- Otherwise, find first nvim pane
  for _, pane in ipairs(tab:panes()) do
    if is_nvim_process(pane) then
      return pane
    end
  end

  return nil
end

-- Handle clicking on a file:line:col link
local function handle_vimjump_uri(window, uri)
  -- Parse vimjump://file:line:col
  local file, line, col = uri:match('^vimjump://(.+):(%d+):(%d*)$')

  if not file or not line then
    window:toast_notification('WezTerm', 'Invalid file path format', nil, 4000)
    return
  end

  -- Find nvim pane
  local nvim_pane = find_nvim_pane(window)
  if not nvim_pane then
    window:toast_notification('WezTerm', 'No Neovim pane found', nil, 4000)
    return
  end

  -- Normalize file path for Windows (convert backslashes to forward slashes)
  local normalized_file = file:gsub('\\', '/')

  -- Build the Vim command sequence
  -- This implements the "reuse-if-open" logic in pure Lua
  local lua_code = string.format(
    [[vim.schedule(function() ]] ..
    [[local file = '%s'; ]] ..
    [[local line = %s; ]] ..
    [[local col = %s; ]] ..
    [[local bufnr = vim.fn.bufnr(file); ]] ..
    [[if bufnr ~= -1 and vim.fn.bufloaded(bufnr) == 1 then ]] ..
      [[local winid = vim.fn.bufwinid(bufnr); ]] ..
      [[if winid ~= -1 then ]] ..
        [[vim.fn.win_gotoid(winid); ]] ..
      [[else ]] ..
        [[local found = false; ]] ..
        [[for _, tab in ipairs(vim.api.nvim_list_tabpages()) do ]] ..
          [[for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do ]] ..
            [[if vim.api.nvim_win_get_buf(win) == bufnr then ]] ..
              [[vim.api.nvim_set_current_tabpage(tab); ]] ..
              [[vim.api.nvim_set_current_win(win); ]] ..
              [[found = true; ]] ..
              [[break; ]] ..
            [[end ]] ..
          [[end ]] ..
          [[if found then break end ]] ..
        [[end ]] ..
        [[if not found then ]] ..
          [[vim.cmd('tabnew'); ]] ..
          [[vim.cmd('buffer ' .. bufnr); ]] ..
        [[end ]] ..
      [[end ]] ..
    [[else ]] ..
      [[if vim.fn.filereadable(file) == 1 then ]] ..
        [[vim.cmd('tabnew ' .. vim.fn.fnameescape(file)); ]] ..
      [[else ]] ..
        [[vim.schedule(function() print('File not found: ' .. file) end); ]] ..
        [[return; ]] ..
      [[end ]] ..
    [[end ]] ..
    [[vim.cmd(tostring(line)); ]] ..
    [[if col and col > 1 then ]] ..
      [[vim.cmd('normal! ' .. tostring(col) .. '|'); ]] ..
    [[end ]] ..
    [[end)]],
    normalized_file:gsub("'", "''"), -- Escape single quotes
    line,
    (col and col ~= '') and col or '1'
  )

  -- Send escape sequence to exit insert mode, then execute the Lua command
  nvim_pane:send_text('\x1b:lua ' .. lua_code .. '\r')
end

-- Register open-uri handler
wezterm.on('open-uri', function(window, pane, uri)
  if uri:match('^vimjump://') then
    handle_vimjump_uri(window, uri)
    return false  -- Prevent default handling
  end
  return true  -- Allow default handling for other URIs
end)

-- Add custom hyperlink rules to config
function M.apply_to_config(config)
  -- Start fresh with default rules
  config.hyperlink_rules = wezterm.default_hyperlink_rules()

  -- Add our custom file:line[:col] pattern
  -- Matches: path/to/file.py:123 or path/to/file.py:123:45 or path\to\file.py:123:45
  table.insert(config.hyperlink_rules, {
    -- Rust regex for file paths with line and optional column numbers
    -- Captures: filename (with path), line number, optional column number
    regex = [[([\w\-\\/\.]+\.\w+):(\d+)(?::(\d+))?]],
    format = 'vimjump://$1:$2:$3',
  })
end

return M