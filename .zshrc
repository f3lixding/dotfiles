ZSH_THEME="robbyrussell"
plugins=(git)

if [[ "$OSTYPE" == "darwin"* ]]; then
    IS_MACOS=true
else
    IS_MACOS=false
fi

if [[ "$IS_MACOS" == true ]]; then
    export ZSH="$HOME/.oh-my-zsh"
    source $ZSH/oh-my-zsh.sh
fi

# Override. Note that this function only works with robbyrussell theme
git_prompt_info() {
    local nix_indicator=""
    if [[ -n "$IN_NIX_SHELL" ]]; then
        nix_indicator="%{$fg_bold[green]%}(nix)%{$reset_color%} "
    fi
    
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
        echo "${nix_indicator}%{$fg_bold[blue]%}jj:(%{$fg_bold[red]%}$bookmark%{$fg_bold[blue]%}$jj_status"
    else
        # Fall back to original git behavior
        command git rev-parse --git-dir &> /dev/null || return 0
        
        local ref
        ref=$(command git symbolic-ref HEAD 2> /dev/null) || \
        ref=$(command git rev-parse --short HEAD 2> /dev/null) || return 0
        
        echo "${nix_indicator}$ZSH_THEME_GIT_PROMPT_PREFIX${ref#refs/heads/}$(parse_git_dirty)$ZSH_THEME_GIT_PROMPT_SUFFIX"
    fi
}

# Add your custom configurations below
# e.g., enable vi mode
bindkey -v

# PATH
export PATH="/Applications/Ghostty.app/Contents/MacOS:$PATH"
export PATH="/opt/homebrew/bin:$PATH"
export PATH="/opt/homebrew/Cellar/zigup/2025.05.24/bin:$PATH"
export PATH="/Users/felixding/.local/share/sokol:$PATH"
# source ~/.api_keys

# mise
# eval "$(mise activate zsh)"

# fzf
source <(fzf --zsh)
bindkey '^R' fzf-history-widget

# editor
export EDITOR=nvim

# jj autocomplete
autoload -Uz compinit
compinit
eval "$(jj util completion zsh)"
