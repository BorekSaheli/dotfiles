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
config.font_size = 11.0


-- Color scheme
config.color_scheme = 'Catppuccin Mocha'

-- GPU configuration for NVIDIA
-- config.webgpu_power_preference = 'HighPerformance'
config.front_end = 'WebGpu'
-- Simplified GPU preference - let WezTerm auto-detect NVIDIA GPU
config.webgpu_force_fallback_adapter = false
config.animation_fps = 60
config.max_fps = 60

-- Window configuration
config.window_background_opacity = 0.95
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


-- Apply process-specific colors
-- Commented out because get_process_colors function is not defined
-- wezterm.on('update-right-status', function(window, pane)
--   local info = pane:get_foreground_process_info()
--   if info and info.name then
--     local colors = get_process_colors(info.name)
--     if colors then
--       local overrides = window:get_config_overrides() or {}
--       overrides.colors = overrides.colors or {}
--       overrides.colors.ansi = colors.ansi
--       overrides.colors.brights = colors.brights
--       window:set_config_overrides(overrides)
--     end
--   end
-- end)

return config