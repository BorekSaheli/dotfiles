local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Import and apply nvim jump module
local nvim_jump = require 'nvim_jump'
nvim_jump.apply_to_config(config)

-- Platform detection
local is_windows = wezterm.target_triple:find("windows") ~= nil
local is_macos = wezterm.target_triple:find("darwin") ~= nil
local is_linux = wezterm.target_triple:find("linux") ~= nil

-- Shell configuration - platform specific
if is_windows then
  config.default_prog = { 'pwsh.exe', '-NoLogo' }
elseif is_macos then
  config.default_prog = { '/bin/zsh', '-l' }
elseif is_linux then
  config.default_prog = { '/bin/zsh', '-l' }
end

-- Font configuration
config.font = wezterm.font {
	family = 'JetBrainsMono Nerd Font Mono',
	harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' },
}

-- Platform-specific font size
if is_macos then
  config.font_size = 15.0
else
  config.font_size = 12.0
end


-- Color scheme
config.color_scheme = 'Catppuccin Mocha'

-- GPU configuration for NVIDIA
-- config.webgpu_power_preference = 'HighPerformance'
config.front_end = 'WebGpu'
-- Simplified GPU preference - let WezTerm auto-detect NVIDIA GPU
config.webgpu_force_fallback_adapter = false
config.animation_fps = 120
config.max_fps = 120

-- Window configuration
-- Platform-specific initial window size
if is_macos then
  config.initial_cols = 200
  config.initial_rows = 60
  -- Start maximized (not fullscreen) on macOS
  wezterm.on('gui-startup', function(cmd)
    local tab, pane, window = wezterm.mux.spawn_window(cmd or {})
    window:gui_window():maximize()
  end)
end

config.window_background_opacity = 1
config.inactive_pane_hsb = {
  hue = 1.0,
  saturation = 1,
  brightness = 1,
}
-- Keep the tab bar customization but remove problematic color overrides
config.colors = {
  -- Override colors for better readability with colored backgrounds
  foreground = '#ffffff', -- Ensure foreground text is pure white
  background = '#000000', -- Ensure background is pure black for contrast
  ansi = {
    '#000000', -- black - dark for contrast
    '#ff6b6b', -- red - bright for visibility
    '#34bd4b', -- green - bright for visibility
    '#dfae00', -- yellow - bright for visibility
    '#4dabf7', -- blue - bright for visibility
    '#a26bfa', -- magenta - bright for visibility
    '#8ce99a', -- cyan - bright for visibility
    '#ffffff', -- white - pure white for maximum contrast
  },
  brights = {
    '#404040', -- bright black (gray)
    '#ff8787', -- bright red
    '#69db7c', -- bright green
    '#ffe066', -- bright yellow
    '#74c0fc', -- bright blue
    '#d0bfff', -- bright magenta
    '#96f2d7', -- bright cyan
    '#ffffff', -- bright white - pure white
  },
  tab_bar = {
    background = '#000000',
    active_tab = {
      bg_color = '#0a0e1a',
      fg_color = '#cdd6f4',
    },
    inactive_tab = {
      bg_color = '#1e1e2e',
      fg_color = '#7f849c',
    },
    inactive_tab_hover = {
      bg_color = '#313244',
      fg_color = '#a6adc8',
    },
  },
}
config.window_decorations = 'RESIZE'
config.window_padding = {
  left = 10,
  right = 10,
  top = 10,
  bottom = 10,
}

-- Smooth scrolling
config.enable_scroll_bar = false
config.min_scroll_bar_height = '2cell'
config.scrollback_lines = 10000




-- Tab bar configuration
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.hide_tab_bar_if_only_one_tab = true

-- Key bindings
config.keys = {
  -- Split panes
  { key = 't', mods = 'CTRL|SHIFT|ALT', action = wezterm.action.SplitPane { direction = 'Down', size = { Percent = 25 }, }, },
  { key = 'r', mods = 'CTRL|SHIFT|ALT', action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' }, },
  { key = 'b', mods = 'CTRL|SHIFT|ALT', action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' }, },
-- Navigate between panes
  {
    key = 'h',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.ActivatePaneDirection 'Left',
  },
  {
    key = 'l',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.ActivatePaneDirection 'Right',
  },
  {
    key = 'k',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.ActivatePaneDirection 'Up',
  },
  {
    key = 'j',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.ActivatePaneDirection 'Down',
  },
  -- Resize panes
  {
    key = 'h',
    mods = 'CTRL|SHIFT|ALT',
    action = wezterm.action.AdjustPaneSize { 'Left', 2 },
  },
  {
    key = 'l',
    mods = 'CTRL|SHIFT|ALT',
    action = wezterm.action.AdjustPaneSize { 'Right', 2 },
  },
  {
    key = 'k',
    mods = 'CTRL|SHIFT|ALT',
    action = wezterm.action.AdjustPaneSize { 'Up', 2 },
  },
  {
    key = 'j',
    mods = 'CTRL|SHIFT|ALT',
    action = wezterm.action.AdjustPaneSize { 'Down', 2 },
  },
  -- Close pane
  {
    key = 'q',
    mods = 'CTRL|SHIFT',
	action = wezterm.action.CloseCurrentPane { confirm = false },
	},
}

-- Launch menu - platform specific
if is_windows then
  config.launch_menu = {
    {
      label = 'PowerShell',
      args = { 'pwsh.exe', '-NoLogo' },
    },
    {
      label = 'PowerShell (Admin)',
      args = { 'pwsh.exe', '-NoLogo' },
      cwd = 'C:\\',
    },
  }
elseif is_macos or is_linux then
  config.launch_menu = {
    {
      label = 'Zsh',
      args = { '/bin/zsh', '-l' },
    },
    {
      label = 'Bash',
      args = { '/bin/bash', '-l' },
    },
  }
end

-- -- Fix directory changes when Neovim LSP processes (like Pyright) run
-- -- Disable OSC 7 directory tracking to prevent path pollution from LSP processes
-- config.set_environment_variables = {
--   WEZTERM_OSC7 = '0',
-- }


-- Custom tab title formatting to show nvim instead of child processes
wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
  local pane = tab.active_pane
  local title = tab.tab_index + 1 .. ': '

  -- Check user vars first - most reliable way to detect nvim
  local user_vars = pane.user_vars or {}
  if user_vars.NVIM or user_vars.NVIM_LISTEN_ADDRESS then
    title = title .. 'nvim'
  else
    -- Check if nvim is in the foreground process name
    local fg_name = pane.foreground_process_name
    if fg_name and fg_name:lower():find('nvim') then
      title = title .. 'nvim'
    else
      -- Check the pane title for nvim
      local pane_title = pane.title or 'shell'
      if pane_title:lower():find('nvim') then
        title = title .. 'nvim'
      else
        -- Fallback to the pane title and remove .exe extension
        pane_title = pane_title:gsub('%.exe$', '')
        title = title .. pane_title
      end
    end
  end

  return {
    { Text = ' ' .. title .. ' ' },
  }
end)

return config
