# Path to your oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Set theme (choose your favorite)
ZSH_THEME="robbyrussell"

# Enable plugins (add the ones you used before)
plugins=(git)

# Source Oh My Zsh
source $ZSH/oh-my-zsh.sh

# Change introduced for learning jj
# Another change introduced for learning jj
# Override. Note that this function only works with robbyrussell theme
git_prompt_info() {
    if [[ -d .jj ]]; then
        # Get current bookmark, default to * if none
        local bookmark=$(jj bookmark list --revisions @ 2>/dev/null | head -1 | awk -F: '{print $1}')
        if [[ -z $bookmark ]]; then
            bookmark="*"
        fi
        
        local jj_status=""
        
        # Check if working copy has changes
        if jj status --no-pager 2>/dev/null | grep -q "Working copy changes:"; then
            jj_status=")%{$fg_bold[yellow]%} ✗ %{$reset_color%}"
        else
            jj_status=")%{$reset_color%} "
        fi

        echo "%{$fg_bold[blue]%}jj:(%{$fg_bold[red]%}$bookmark%{$fg_bold[blue]%}$jj_status"
    else
        # Fall back to original git behavior
        command git rev-parse --git-dir &> /dev/null || return 0
        
        local ref
        ref=$(command git symbolic-ref HEAD 2> /dev/null) || \
        ref=$(command git rev-parse --short HEAD 2> /dev/null) || return 0
        
        echo "$ZSH_THEME_GIT_PROMPT_PREFIX${ref#refs/heads/}$(parse_git_dirty)$ZSH_THEME_GIT_PROMPT_SUFFIX"
    fi
}

# Add your custom configurations below
# e.g., enable vi mode
bindkey -v

# fzf
source <(fzf --zsh)
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
