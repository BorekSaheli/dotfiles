local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Each module exposes apply(config). Comment one out to disable that feature.
for _, name in ipairs { 'platform', 'appearance', 'keys', 'tabs', 'nvim_jump' } do
  require(name).apply(config)
end

return config
