-- Where am I? Every other module reads platform.os instead of re-deriving it.
local wezterm = require 'wezterm'
local M = {}

local triple = wezterm.target_triple
M.os = triple:find 'windows' and 'windows'
    or triple:find 'darwin' and 'macos'
    or 'linux'

function M.apply(config)
  if M.os == 'windows' then
    config.default_prog = { 'pwsh.exe', '-NoLogo' }
    -- Work machine only: open in the code dir when it exists.
    local work = 'C:\\Users\\borek.saheli\\code'
    if pcall(wezterm.read_dir, work) then
      config.default_cwd = work
    end
  end
  -- Linux/macOS: default_prog left unset -> WezTerm uses the login shell.
end

return M
