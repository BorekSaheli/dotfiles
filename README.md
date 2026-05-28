# dotfiles

Cross-platform dotfiles managed with [chezmoi](https://www.chezmoi.io/).
macOS / Linux use zsh; Windows uses PowerShell + [komorebi](https://github.com/LGUG2Z/komorebi) + WezTerm.

## Windows: one-command bootstrap

On a **brand-new Windows machine**, open PowerShell and run:

```powershell
irm https://raw.githubusercontent.com/BorekSaheli/dotfiles/main/bootstrap.ps1 | iex
```

This is *one command, after a ~30-second bootstrap* — not literally zero-setup,
because winget + DSC support must exist first. `bootstrap.ps1` handles that for
you, then pulls the whole system together:

1. **Prelude** — ensures `winget` (App Installer) is present and recent enough,
   and enables the DSC `configuration` feature.
2. **`winget configure`** — applies [`winget-configure.dsc.yaml`](winget-configure.dsc.yaml),
   installing Git, PowerShell 7, Neovim, WezTerm, Starship, lazygit, komorebi,
   whkd, fastfetch, and chezmoi. Runs **fully silent**
   (`--accept-configuration-agreements --disable-interactivity`).
3. **chezmoi handoff** — `bootstrap.ps1` then runs `chezmoi init --apply`,
   which clones this repo over HTTPS and lays down every config file. Your
   PowerShell profile loaders are wired up automatically by the
   `run_once_before_setup-powershell-profiles` script.

When it finishes, open a fresh terminal to pick up the new PATH and profile.

### Caveats

- **Neovim config (SSH):** [`.chezmoiexternal.toml`](.chezmoiexternal.toml)
  pulls the Neovim config from a separate repo over **SSH**
  (`git@github.com:...`). A fresh machine has no SSH key, so that external is
  skipped during the first run. Once you've generated/loaded an SSH key, run
  `chezmoi apply` again to fetch it.
- **Trust:** the bootstrap auto-accepts the DSC configuration agreement so the
  run is non-interactive. Inspect [`winget-configure.dsc.yaml`](winget-configure.dsc.yaml)
  before running if you want to confirm what gets installed.
- **Coverage gaps:** anything without a winget package or DSC resource (certain
  Windows tweaks) still needs a manual step or a custom script resource.

## macOS / Linux

Install chezmoi, then:

```sh
chezmoi init --apply BorekSaheli/dotfiles
```

## Layout

| Path | What |
|---|---|
| `bootstrap.ps1` | Windows fresh-machine bootstrap (winget + DSC + chezmoi) |
| `winget-configure.dsc.yaml` | winget DSC config: the package list |
| `dot_config/` | `~/.config` (powershell, komorebi, wezterm, starship, git) |
| `dot_claude/` | `~/.claude` (settings, agents, commands) |
| `.chezmoiexternal.toml` | external repos (Neovim config) |
