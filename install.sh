# mkdir -p ~/.config/nvim
NEO_VIM_DIR_DEST="/Users/$USER/.config/nvim"
NEO_VIM_DIR_SOURCE="./neovim_config"
TMUX_DIR_DEST="/Users/$USER/.tmux.conf"
TMUX_DIR_SOURCE="./tmux.conf"

# determine OS
[[ "$OSTYPE" == "linux-gnu"* ]] && OS="LINUX" || OS="NON-LINUX"

# doing some actual work now
if [ -d "$NEO_VIM_DIR_DEST" ]; then
  echo "neovim config already exists"
  echo "Please delete said directory if you wish to reconfigure neovim"
else
  echo "Symlinking neovim related folders..."
  ln -s $NEO_VIM_DIR_SOURCE $NEO_VIM_DIR_DEST
  echo "You would still need to do the following:"
  echo "1. Update the language server init options;"
  echo "2. Install the plugins;"
fi

if [ -d "$TMUX_DIR_DEST" ]; then
  echo "tmux config already exists"
  echo "Please delete said config if you wish to reconfigure tmux"
else 
  echo "Symlinking tmux config..."
  ln -s $TMUX_DIR_SOURCE $TMUX_DIR_DEST
fi

