# Path to your oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Set theme (choose your favorite)
ZSH_THEME="robbyrussell"

# Enable plugins (add the ones you used before)
plugins=(git)

# Source Oh My Zsh
source $ZSH/oh-my-zsh.sh

# Add your custom configurations below
# e.g., enable vi mode
bindkey -v

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
bindkey '^R' fzf-history-widget

# PATH
export PATH="/Applications/Ghostty.app/Contents/MacOS:$PATH"
export PATH="/opt/homebrew/bin:$PATH"
export PATH="/Users/felixding/.local/share/sokol:$PATH"
source ~/.api_keys

# mise
eval "$(mise activate zsh)"

# jj autocomplete
eval "$(jj util completion zsh)"
