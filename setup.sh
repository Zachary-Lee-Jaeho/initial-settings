#!bin/zsh

# If zsh is not installed, notify and install it
if ! [ -x "$(command -v zsh)" ]; then
  echo 'Error: zsh is not installed.' >&2
  echo ' Please run this script again after install zsh and oh-my-zsh.' >&2
  exit 1
fi

# if zsh is not the default shell notify and change it when user type yes
if [ "$SHELL" != "/bin/zsh" ]; then
  echo "Your default shell is not zsh. Do you want to change it? (yes/no)"
  read answer
  if [ "$answer" == "yes" ]; then
    chsh -s $(which zsh)
  elif [ "$answer" == "no" ]; then
    echo "Please run this script again after changing the default shell to zsh."
    exit 1
  else
    echo "Please answer yes or no."
    exit 1
  fi
fi

# Install oh-my-zsh if it is not installed
if [ ! -d ~/.oh-my-zsh ]; then
  echo "Installing oh-my-zsh..."
  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi



# Install tmux tpm
echo "Installing tmux tpm..."
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

echo "Creating symbolic links..."
ln -s ~/.local/initial-settings/tmux/tmux.conf ~/.tmux.conf

# Install neovim if it is not installed
if ! [ -x "$(command -v nvim)" ]; then
  echo "Neovim is not installed. Do you want to install it? (yes/no)"
  read answer
  if [ "$answer" == "yes" ]; then
    echo "Installing neovim (v0.9.5)..."
    cd neovim
    wget https://github.com/neovim/neovim/releases/download/v0.9.5/nvim-linux64.tar.gz
    tar xzf nvim-linux64.tar.gz
    echo "alias nvim='~/.local/initial-settings/neovim/nvim-linux64/bin/nvim'" >> ~/.zshrc
    echo "export PATH=$PATH:~/.local/initial-settings/neovim/nvim-linux64/bin" >> ~/.zshrc
    export PATH=$PATH:~/.local/initial-settings/neovim/nvim-linux64/bin

    echo "Finished installing neovim"
    echo "If you want to use neovim as default vim editor, run the following command:\necho "alias vim='nvim'" >> ~/.zshrc"
  elif [ "$answer" == "no" ]; then
    echo "Please run this script again after installing neovim."
    exit 1
  else 
    echo "Please answer yes or no."
    exit 1
  fi
fi

# if there is .config/nvim directory, ask to remove it and create symbolic link
# and if the answer is neither yes nor no, ask again
# if the answer is yes, remove the directory and create symbolic link
# if the answer is no, notify the user to remove the directory and run the script again
if [ -d ~/.config/nvim ]; then
  echo "There is a ~/.config/nvim directory. Do you want to remove it and create a symbolic link? (yes/no)"
  read answer
  if [ "$answer" == "yes" ]; then
    echo "Creating symbolic links for neovim..."
    rm -rf ~/.config/nvim
    ln -s ~/.local/initial-settings/neovim/nvim-settings ~/.config/nvim
    echo "All done!"
  elif [ "$answer" == "no" ]; then
    echo "Please remove the ~/.config/nvim directory and run the script again."
    exit 1
  else
    echo "Please answer yes or no."
    exit 1
  fi
else
  ln -s ~/.local/initial-settings/nvim ~/.config/nvim
fi

echo "\n"
echo "Please run the tmux and 'F2+Shift+I' to install the settings"
echo "Please run the nvim and run :MasonIntallAll to install the rest of the plugins"
echo "Read the https://github.com/NvChad/NvChad/tree/v2.5 to get more information about nvim settings"


