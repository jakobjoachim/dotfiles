# vim:ft=ruby

if OS.mac?
    # taps
    tap "homebrew/cask"
    tap "homebrew/cask-fonts"
    tap "koekeishiya/formulae"
    
    brew "noti" # utility to display notifications from scripts

    cask "wezterm" # a better terminal emulator

    # yabai
    brew "yabai"
    brew "skhd"

    # Fonts
    cask "font-fira-code"
    cask "font-jetbrains-mono"
    cask "font-cascadia-mono"
    cask "font-symbols-only-nerd-font"
    cask "font-recursive-code"
    cask "font-overpass"
    cask "font-overpass-mono"
    cask "font-overpass-nerd-font"
elsif OS.linux?
    brew "xclip" # access to clipboard (similar to pbcopy/pbpaste)
end

tap "homebrew/bundle"
tap "homebrew/core"
tap "1password/tap"

# packages
cask "1password-cli"
brew "bat" # better cat
brew "cloc" # lines of code counter
brew "entr" # file watcher / command runner
brew "exa" # ls alternative
brew "fd" # find alternative
brew "fnm" # Fast Node version manager
brew "fzf" # Fuzzy file searcher, used in scripts and in vim
brew "gh" # GitHub CLI
brew "git" # Git version control (latest version)
brew "git-delta" # a better git diff
brew "glow" # markdown viewer
brew "gnupg" # GPG
brew "grep" # grep (latest)
brew "highlight" # code syntax highlighting
brew "htop" # a top alternative
brew "jq" # work with JSON files in shell scripts
brew "lazygit" # a better git UI
brew "neofetch" # pretty system info
brew "neovim" # A better vim
brew "python" # python (latst)
brew "ripgrep" # very fast file searcher
brew "shellcheck" # diagnostics for shell sripts
brew "stow" # dotfile manager
brew "tmux" # terminal multiplexer
brew "tree" # pretty-print directory contents
brew "vim" # Vim (latest)
brew "watch" # execute a command every so often
brew "wdiff" # word differences in text files
brew "wget" # internet file retriever
brew "z" # switch between most used directories
brew "zoxide" # switch between most used directories
brew "zsh" # zsh (latest)

# dev ops packages
tap "derailed/k9s" # k9s
tap "kudobuilder/tap" # kuttl

brew "helm"
brew "k9s"
brew "kind"
brew "kuttl-cli"
brew "warrensbox/tap/tfswitch"
brew "rclone"
