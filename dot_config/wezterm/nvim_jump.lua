-- Click a `path/file.ext:LINE[:COL]` in any pane -> jump there in the Neovim
-- pane of the current tab (reusing an existing buffer/window when possible).
local wezterm = require 'wezterm'
local util = require 'util'
local M = {}

-- Neovim-side logic, executed via `:lua`. %s = file, line, col.
local JUMP = [[
vim.schedule(function()
  local file, line, col = '%s', %s, %s
  local bufnr = vim.fn.bufnr(file)
  if bufnr ~= -1 and vim.fn.bufloaded(bufnr) == 1 then
    local winid = vim.fn.bufwinid(bufnr)
    if winid ~= -1 then
      vim.fn.win_gotoid(winid)
    else
      local found = false
      for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
          if vim.api.nvim_win_get_buf(win) == bufnr then
            vim.api.nvim_set_current_tabpage(tab)
            vim.api.nvim_set_current_win(win)
            found = true
            break
          end
        end
        if found then break end
      end
      if not found then
        vim.cmd('tabnew')
        vim.cmd('buffer ' .. bufnr)
      end
    end
  elseif vim.fn.filereadable(file) == 1 then
    vim.cmd('tabnew ' .. vim.fn.fnameescape(file))
  else
    print('File not found: ' .. file)
    return
  end
  vim.cmd(tostring(line))
  if col > 1 then vim.cmd('normal! ' .. col .. '|') end
end)]]

local function find_nvim_pane(window)
  local tab = window:active_tab()
  if not tab then
    return nil
  end
  for _, pane in ipairs(tab:panes()) do
    if util.is_nvim(pane) then
      return pane
    end
  end
end

local function jump(window, uri)
  local file, line, col = uri:match '^vimjump://(.+):(%d+):(%d*)$'
  if not file then
    wezterm.log_error('nvim_jump: bad uri ' .. uri)
    return
  end
  local pane = find_nvim_pane(window)
  if not pane then
    window:toast_notification('WezTerm', 'No Neovim pane found', nil, 4000)
    return
  end
  file = file:gsub('\\', '/'):gsub("'", "''")
  local code = string.format(JUMP, file, line, col ~= '' and col or '1'):gsub('\n%s*', ' ')
  pane:send_text('\x1b:lua ' .. code .. '\r') -- ESC first: leave insert mode
end

function M.apply(config)
  config.hyperlink_rules = wezterm.default_hyperlink_rules()
  table.insert(config.hyperlink_rules, {
    -- path/to/file.ext:123  or  path\to\file.ext:123:45
    regex = [[([\w\-\\/\.]+\.\w+):(\d+)(?::(\d+))?]],
    format = 'vimjump://$1:$2:$3',
  })

  wezterm.on('open-uri', function(window, _, uri)
    if uri:find('vimjump://', 1, true) == 1 then
      jump(window, uri)
      return false
    end
    return true
  end)
end

return M
