# show weather in Hamburg
alias wttr="curl wttr.in/Hamburg"

# Show/hide hidden files in the Finder
alias showfiles="defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder"
alias hidefiles="defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder"

# Filesystem aliases
alias ..="cd .."
alias ...='cd ../..'
alias ....="cd ../../.."
alias .....="cd ../../../.."

# better ls
alias ls="exa"
alias ll="exa --icons --git --long"
alias l="exa --icons --git --all --long"
alias ld="exa --icons --git --all --long --only-dirs"

# git shortcuts
# not quite working yet
# alias gitrmo="git branch -vv | grep ': gone]'| grep -v '\*' | awk '{ print $1; }' | xargs -r git branch -D"

# reload zsh config
alias reload!='RELOAD=1 source ~/.zshrc'
