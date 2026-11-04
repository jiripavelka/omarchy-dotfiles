# Omarchy dotfiles

Personal configuration of an [Omarchy](https://omarchy.org/) machine, backed up
automatically once a day by `~/.local/bin/dotfiles-sync` (systemd user timer
`dotfiles-sync.timer`).

| Path | What |
|------|------|
| `home/` | Files under `~`: Hyprland (`.config/hypr`), Omarchy shell (`shell.json`, own plugins, themes, hooks, menu extensions), terminals, nvim, herdr, own scripts in `.local/bin`, user systemd units |
| `etc/` | System files changed by hand (e.g. logind lid handling) |
| `meta/` | Package lists, shell plugins installed from git, enabled plugins and user units, default browser |

Private data is never stored: no git identity, tokens, keys or e-mail addresses.
The sync refuses to push if it finds any (local pattern list + gitleaks).

## Restore on a new machine

```bash
git clone https://github.com/jiripavelka/omarchy-dotfiles ~/.local/share/dotfiles
cd ~/.local/share/dotfiles
./restore --dry-run   # see what would change
./restore
```

Then set by hand: git identity, `gh auth login`, SSH keys, `rbw login`, and check
`monitors.lua` / `input.lua` against the new hardware. To keep backing up from the
new machine, also run `systemctl --user enable --now dotfiles-sync.timer` and
create `~/.config/dotfiles/private-patterns` (one private string per line).
