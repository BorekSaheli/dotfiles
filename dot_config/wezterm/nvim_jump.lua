local wezterm = require 'wezterm'

local M = {}

-- Check if nvim is in the process tree (including parent processes)
local function is_nvim_process(pane)
  -- Check foreground process info for parent processes
  local fg_info = pane:get_foreground_process_info()

  -- Debug logging
  wezterm.log_info('=== Checking nvim process ===')
  if fg_info then
    wezterm.log_info('fg_info.name: ' .. (fg_info.name or 'nil'))
    wezterm.log_info('fg_info.executable: ' .. (fg_info.executable or 'nil'))
    if fg_info.argv then
      wezterm.log_info('fg_info.argv[0]: ' .. (fg_info.argv[1] or 'nil'))
    end
    if fg_info.cwd then
      wezterm.log_info('fg_info.cwd: ' .. fg_info.cwd)
    end
  end

  local process_name = pane:get_foreground_process_name()
  wezterm.log_info('get_foreground_process_name: ' .. (process_name or 'nil'))

  local user_vars = pane:get_user_vars()
  wezterm.log_info('user_vars.NVIM: ' .. (user_vars.NVIM or 'nil'))

  -- Check foreground process name first
  if fg_info and fg_info.name then
    local fg_name = fg_info.name:lower()
    if fg_name:find('nvim') or fg_name:find('vim') then
      wezterm.log_info('Found nvim in fg_info.name')
      return true
    end
  end

  -- Check user vars set by shell integration
  if user_vars.NVIM then
    wezterm.log_info('Found nvim in user_vars.NVIM')
    return true
  end

  -- Check the process tree
  if process_name then
    local name = process_name:lower()
    if name:find('nvim') or name:find('vim') then
      wezterm.log_info('Found nvim in process_name')
      return true
    end
  end

  -- Check executable path
  if fg_info and fg_info.executable then
    local exe = fg_info.executable:lower()
    if exe:find('nvim') or exe:find('vim') then
      wezterm.log_info('Found nvim in executable path')
      return true
    end
  end

  wezterm.log_info('No nvim found')
  return false
end

-- Find the active nvim pane in the current window
local function find_nvim_pane(window)
  local tab = window:active_tab()
  if not tab then
    return nil
  end

  wezterm.log_info('=== Searching for nvim pane ===')
  wezterm.log_info('Total panes in tab: ' .. #tab:panes())

  -- Check all panes and log their info
  for i, pane in ipairs(tab:panes()) do
    wezterm.log_info('--- Pane ' .. i .. ' ---')
    if is_nvim_process(pane) then
      wezterm.log_info('Found nvim in pane ' .. i)
      return pane
    end
  end

  wezterm.log_info('No nvim pane found in any pane')
  return nil
end

-- Handle clicking on a file:line:col link
local function handle_vimjump_uri(window, uri)
  wezterm.log_info('========================================')
  wezterm.log_info('HANDLE VIMJUMP URI CALLED')
  wezterm.log_info('URI: ' .. uri)

  -- Parse vimjump://file:line:col
  local file, line, col = uri:match('^vimjump://(.+):(%d+):(%d*)$')

  if not file or not line then
    wezterm.log_error('Invalid file path format')
    window:toast_notification('WezTerm', 'Invalid file path format', nil, 4000)
    return
  end

  wezterm.log_info('Parsed - File: ' .. file .. ', Line: ' .. line .. ', Col: ' .. (col or 'none'))

  -- Find nvim pane
  local nvim_pane = find_nvim_pane(window)
  if not nvim_pane then
    wezterm.log_error('No nvim pane found - showing notification')
    window:toast_notification('WezTerm', 'No Neovim pane found', nil, 4000)
    return
  end

  wezterm.log_info('Found nvim pane, sending command')

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