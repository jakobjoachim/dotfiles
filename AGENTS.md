# AGENTS

This repository captures Jakob Joachim's personal macOS/Linux dotfiles plus supporting CLI tools. Acting as an agent here mostly means editing shell/Lua/JSON config safely, keeping install flows reproducible, and never overwriting local tweaks in `~/.gitconfig-local` or other untracked overlays.

## Repository Map
- `install.sh`: orchestrates linking, Homebrew setup, shell defaults, sdkman install, and macOS defaults.
- `bin/`: small helper executables (`killport`, `extract`, `aax_to_mp4`) invoked directly from PATH.
- `config/`: items mirrored into `~/.config` (git, nvim, opencode, sdkman, skhd, wezterm, yabai).
- `zsh/`: login shell bootstrap (`zshrc.symlink`, aliases, functions, prompt) plus user specific symlinks.
- `Brewfile`: declarative list of brew/cask taps and packages; macOS-focused but guards for Linux.
- `.editorconfig`: single source of truth for indentation (2 spaces default, 4 spaces for `*.vim`).
- There are no `.cursor/rules`, `.cursorrules`, or `.github/copilot-instructions.md`; no extra AI guardrails beyond this file.

## Prerequisites & Common Tooling
- Homebrew is required for the bootstrap script; install section auto-runs on macOS if missing.
- `volta`, `sdkman`, `bun`, and `zoxide` are automatically initialized inside `zsh/zshrc.symlink` when available.
- `shellcheck`, `ripgrep`, `fzf`, `gh`, and `git-delta` are part of the Brewfile baseline; rely on those versions for linting and diffing.
- Node tooling in `config/opencode` is bun-first (`bun.lock`) but also compatible with npm/yarn if bun unavailable.
- `nvim` configuration assumes `lazy.nvim` plus Nerd Font icons; `vim.g.have_nerd_font` is set to `true` in `config/nvim/init.lua`.

## Build, Lint, and Test Commands
### Bootstrapping Dotfiles
- Dry-run installs are not supported; use flags to limit scope. Primary targets:
  ```bash
  ./install.sh link        # symlink dotfiles and ~/.config entries
  ./install.sh homebrew    # ensure brew + Brewfile packages
  ./install.sh shell       # register Homebrew zsh and change default shell
  ./install.sh macos       # apply defaults write settings (macOS only)
  ./install.sh all         # run every step above (idempotent per step)
  ```
- The script expects to run from repo root; it relies on `find`, `ln -s`, and `ln` relative paths inside `setup_symlinks`.

### Homebrew Bundle Validation
- Always sync formulae via `brew bundle install --file=Brewfile`.
- Use `brew bundle check --file=Brewfile --no-upgrade` before committing changes so CI instructions can be trusted.
- When testing a single package change, run `brew bundle exec <tool>` or `brew info <formula>` instead of reinstalling the full bundle.

### Neovim Configuration Health
- Install plugins once with `nvim --headless '+Lazy! sync' +qa` to materialize `lazy-lock.json` updates when plugins change.
- Run the maintained health check in `config/nvim/lua/kickstart/health.lua` headlessly:
  ```bash
  nvim --headless \
    "+lua require('kickstart.health').check()" \
    +qa
  ```
- Smoke-test new keymaps or options with `nvim --clean -u config/nvim/init.lua` to ensure startup works without cached state.

### Shell Scripts & Utilities
- Lint any Bash/Zsh file with Homebrew `shellcheck` (already available via Brewfile). Examples:
  ```bash
  shellcheck install.sh
  shellcheck config/yabai/yabairc
  shellcheck bin/killport
  ```
- For zsh-specific functions (e.g., `bin/extract`), run `zsh -n <file>` to catch syntax errors that shellcheck may miss.
- Execution tests rely on deterministic commands; e.g., verify `bin/killport` with `lsof -ti tcp:<port>` and a dummy `nc -l` server.

### Yabai & skhd Config Checks (macOS)
- Validate the tiling config without restarting services:
  ```bash
  /usr/local/bin/yabai --check-config config/yabai/yabairc
  /usr/local/bin/skhd --check < config/skhd/skhdrc
  ```
- Apply live changes using the launch agents (outside this repo) or reload via `brew services restart {yabai,skhd}`.

### Node/Bun Environment for opencode
- Manage dependencies from `config/opencode` using bun to respect the existing lockfile:
  ```bash
  (cd config/opencode && bun install)
  ```
- No package scripts are defined; new tooling should add `package.json` scripts and commit the updated `bun.lock`.
- Prefer `bunx <tool>` or `npx --yes <tool>` to keep global installations minimal.

## Single-Test Cheatsheet (per user request)
- Shell script lint on one file: `shellcheck bin/killport`.
- Run the Neovim health test alone: `nvim --headless "+lua require('kickstart.health').check()" +qa`.
- Probe a single brew formula from the bundle: `brew bundle exec which <binary>` (ensures it is supplied by Brewfile).
- Validate one YAML/JSON file with `python -m json.tool config/opencode/config.json` or `yq eval '.' config/yabai/yabairc` depending on format.
- For macOS automation, isolate a defaults command via `defaults read` before applying `install.sh macos`; e.g., `defaults read NSGlobalDomain AppleShowAllExtensions`.

## Code Style Guidelines
### General Formatting (`.editorconfig`)
- Default indent: 2 spaces, LF line endings, final newline required.
- `*.vim` sticks to 4 spaces; keep comment-based folding intact.
- YAML/JSON/TOML all inherit two spaces; avoid tabs entirely.
- Keep lines reasonably short (<100 chars) unless copying literal paths.

### Shell & Bash (`install.sh`, `config/yabai/yabairc`, `bin/*`)
- Use `#!/usr/bin/env bash` for Bash scripts and `#!/usr/bin/env zsh` (or omit) for Zsh-specific helpers.
- Structure scripts around small functions (`title`, `error`, `warning`, `info`) and call them from a `case "$1"` dispatcher.
- Prefer `local` variables inside functions and quote expansions (`"$var"`) consistently.
- Use `[[ ... ]]` tests and `case` expressions for pattern matching; no `[`/`]` or `test` unless portability demands it.
- When touching macOS defaults, log each intent with `echo` like the existing `setup_macos` block.
- Rely on brew-installed executables by name (e.g., `grep` resolves to GNU grep because PATH is patched in `zshrc.symlink`).

### Zsh Config (`zsh/zshrc.symlink`, `zsh/aliases.zsh`, `zsh/functions/*`)
- Autoload modular functions via `autoload -U` and keep each helper in its own file under `zsh/functions`.
- Add aliases using lowercase names (`alias wttr=...`) unless mirroring a literal CLI option.
- Source ordering matters: exports happen before `zfetch` plugin pulls; insert new env vars above plugin hooks when they influence plugin behavior.
- Use `setopt` judiciously; append to the existing option groups instead of redefining them elsewhere.

### Lua / Neovim (`config/nvim/**/*.lua`, `config/wezterm/wezterm.lua`)
- Favor `local` tables and `require('module')` calls at the top of files; avoid polluting `_G`.
- Stick with single quotes for strings unless interpolation/escape-heavy (Kickstart already follows this).
- Use trailing commas in multi-line tables to keep diffs tidy (`opts = { delay = 0, icons = { ... }, }`).
- Keymaps go through `vim.keymap.set` with a `desc`; diagnostics use `vim.diagnostic.config` and `vim.health.*` helpers.
- Keep plugin specs declarative, returning a Lua table from each module (see `config/nvim/lua/custom/plugins/init.lua`).
- For wezterm, return a plain `config` table after populating values; avoid side effects besides `require("wezterm")`.

### JSON & Bun (`config/opencode/config.json`, `config/opencode/package.json`)
- Two-space indent, double quotes, trailing commas disallowed (JSON spec).
- Keep `$schema` references at the top when available; align provider entries alphabetically by key.
- Update `bun.lock` via `bun install` and commit both lock and manifest together.

### Brewfile (Ruby DSL)
- Maintain guard blocks for `OS.mac?` vs `OS.linux?`; add new taps/brews inside the correct branch.
- Comment each package with a short rationale (existing file uses inline comments extensively—follow that style).
- Order: taps ➜ casks ➜ brews ➜ devops packages.

### Git Config (`config/git/config`, `config/git/ignore`)
- Keep sections alphabetized where practical; alias keys are grouped logically (log, push, rebase, grep).
- New aliases should use the `!` shell form only when necessary and escape internal quotes the way `delete-merged-branches` does.
- `.gitconfig-local` is intentionally excluded; never add secrets here.

## Imports & Dependencies
- Shell scripts should assume utilities from Brewfile exist; guard Linux-only paths with `if [[ "$(uname)" == "Linux" ]]` as in `setup_homebrew`.
- Lua code should prefer lazy-loading modules via plugin `opts` rather than `require` side effects. Use `pcall(require('telescope').load_extension, 'fzf')` when extensions may be missing.
- Zsh uses `zfetch` to pull plugins into `$CACHEDIR`; register new plugins by extending the associative `plugins` map next to current entries.
- Node/Bun dependencies live strictly inside `config/opencode`; do not add repo-wide `package.json` unless absolutely necessary.

## Error Handling & Logging
- Bash: use `error()` to exit with a message, `warning()` for recoverable states, and `info()`/`success()` for progress updates, mirroring `install.sh`'s helpers.
- Lua: prefer `error()` with descriptive text or Neovim's `vim.notify`/`vim.health.*` utilities depending on context.
- Git automation should never call destructive commands (no `git reset --hard`)—follow the alias set in `config/git/config`.

## Environmental Assumptions & Secrets
- User-specific overrides live in files ending with `.local` (`~/.gitconfig-local`, `~/.zshrc.local`, `~/.localrc`) and must remain untracked.
- kubeconfigs live under `~/.kube/configs/` (documented in README); do not hardcode cluster names here.
- `PATH` is already extended for bun (`$HOME/.bun`), opencode (`~/.opencode/bin`), and volta-managed Node; rely on those rather than absolute paths when possible.

## Collaboration Tips
- Keep commits scoped to one tool (e.g., "update wezterm config" vs bundling shell changes).
- Mention in PR/commit messages which bootstrap steps (`install.sh link`, `brew bundle`) must be re-run.
- When adding new scripts, also document them in `README.md` or `AGENTS.md` so future agents discover them.
- Default assumption is macOS; guard Linux behaviors just like `Brewfile` does.

## Missing AI Rule Files
- No Cursor or Copilot instruction files exist right now; this document is the canonical agent guide.
