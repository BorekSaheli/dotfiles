local wezterm = require 'wezterm'
local platform = require 'platform'
local M = {}

function M.apply(config)
  -- Font
  config.font = wezterm.font('JetBrainsMono Nerd Font Mono', {
    harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' }, -- no ligatures
  })
  config.font_size = platform.os == 'macos' and 15 or 12

  -- Colors: Catppuccin Mocha on pure black
  local scheme = wezterm.color.get_builtin_schemes()['Catppuccin Mocha']
  config.color_scheme = 'Catppuccin Mocha'
  config.window_background_opacity = 0.8
  config.colors = {
    background = '#000000',
    foreground = scheme.foreground,
    tab_bar = {
      background = '#000000',
      active_tab = { bg_color = '#0a0e1a', fg_color = scheme.foreground },
      inactive_tab = { bg_color = scheme.background, fg_color = scheme.brights[1] },
      inactive_tab_hover = { bg_color = scheme.selection_bg, fg_color = scheme.ansi[8] },
    },
  }

  -- Window
  config.window_decorations = 'RESIZE'
  config.window_padding = { left = 10, right = 10, top = 10, bottom = 10 }
  config.enable_scroll_bar = false
  config.scrollback_lines = 10000
  config.window_close_confirmation = 'NeverPrompt'
  config.check_for_updates = false

  -- Tab bar
  config.use_fancy_tab_bar = false
  config.hide_tab_bar_if_only_one_tab = true

  -- Rendering. WebGpu: the GL/EGL path has been flaky on the nvidia+Wayland
  -- machines and WebGpu is fine everywhere else, so use it unconditionally.
  config.front_end = 'WebGpu'
  config.max_fps = 120
  config.animation_fps = 120

  if platform.os == 'macos' then
    wezterm.on('gui-startup', function(cmd)
      local _, _, window = wezterm.mux.spawn_window(cmd or {})
      window:gui_window():maximize()
    end)
  end
end

return M
