#!/bin/zsh

# Function to check if sudo is available
use_sudo() {
  if sudo -n true 2>/dev/null; then
    echo "sudo"
  else
    echo ""
  fi
}

SUDO=$(use_sudo)

echo "Installing prerequisites..."
$SUDO apt-get update
$SUDO apt-get install -y curl wget


# If zsh is not installed, notify and install it
if ! [[ -x "$(command -v zsh)" ]]; then
  echo 'Error: zsh is not installed.' >&2
  echo ' Please run this script again after install zsh and oh-my-zsh.' >&2
  exit 1
fi

# If zsh is not the default shell, notify and change it when user types yes
if [[ "$SHELL" != "$(which zsh)" ]]; then
  echo "\n"
  echo "Your default shell is not zsh. Do you want to change it? (yes/no)"
  while true; do
    read answer
    if [[ "$answer" == "yes" ]]; then
      chsh -s $(which zsh)
      break
    elif [[ "$answer" == "no" ]]; then
      echo "Please run this script again after changing the default shell to zsh."
      exit 1
    else
      echo "Please answer yes or no."
    fi
  done
fi

# Install oh-my-zsh if it is not installed
if [[ ! -d ~/.oh-my-zsh ]]; then
  echo "\n"
  echo "Now you need to install oh-my-zsh."
  echo "After installing oh-my-zsh, please run this script again. (press enter to continue)"
  read answer
  echo "Installing oh-my-zsh..."
  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# If tmux is not installed, notify and install it
if ! [[ -x "$(command -v tmux)" ]]; then
  echo "\n"
  echo "Tmux is not installed. Do you want to install it? (yes/no)"
  while true; do
    read answer
    if [[ "$answer" == "yes" ]]; then
      echo "Installing tmux..."
      $SUDO apt-get install tmux
      break
    elif [[ "$answer" == "no" ]]; then
      echo "Please run this script again after installing tmux."
      exit 1
    else
      echo "Please answer yes or no."
    fi
  done
fi

# Install tmux tpm if it is not installed
if [[ ! -d ~/.tmux/plugins/tpm ]]; then
  echo "Installing tmux tpm..."
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# If there is a .tmux.conf file, ask to remove it and create symbolic link
if [[ -f ~/.tmux.conf ]]; then
  echo "\n"
  echo "There is a ~/.tmux.conf file. Do you want to remove it and apply my setting? (yes/no)"
  while true; do
    read answer
    if [[ "$answer" == "yes" ]]; then
      echo "Creating symbolic links..."
      /bin/rm ~/.tmux.conf
      /bin/ln -s ~/.local/initial-settings/tmux/tmux.conf ~/.tmux.conf
      break
    elif [[ "$answer" == "no" ]]; then
      echo "Please remove the ~/.tmux.conf file and run the script again."
      exit 1
    else
      echo "Please answer yes or no."
    fi
  done
fi

# Install neovim if it is not installed
if ! [[ -x "$(command -v nvim)" ]]; then
  echo "\n"
  echo "Neovim is not installed. Do you want to install it? (yes/no)"
  while true; do
    read answer
    if [[ "$answer" == "yes" ]]; then
      echo "Installing neovim (v0.10.1)..."
      cd neovim
      wget https://github.com/neovim/neovim/releases/download/v0.10.1/nvim-linux64.tar.gz
      tar xzf nvim-linux64.tar.gz
      echo "alias nvim='$HOME/.local/initial-settings/neovim/nvim-linux64/bin/nvim'" >> ~/.zshrc
      echo "alias vim='nvim'" >> ~/.zshrc
      export PATH=\$PATH:~/.local/initial-settings/neovim/nvim-linux64/bin
      echo "Finished installing neovim"
      break
    elif [[ "$answer" == "no" ]]; then
      echo "Please run this script again after installing neovim."
      exit 1
    else 
      echo "Please answer yes or no."
    fi
  done
fi

# If there is a ~/.config/nvim directory, ask to remove it and create symbolic link
if [[ -d ~/.config/nvim ]]; then
  echo "\n"
  echo "There is a ~/.config/nvim directory. Do you want to remove it and create a symbolic link? (yes/no)"
  while true; do
    read answer
    if [[ "$answer" == "yes" ]]; then
      echo "Installing nodejs and npm..."
      $SUDO apt install -y nodejs npm
      echo "Creating symbolic links for neovim..."
      /bin/rm -rf ~/.config/nvim
      mkdir -p ~/.config
      /bin/ln -s ~/.local/initial-settings/neovim/nvim-settings ~/.config/nvim
      echo "All done!"
      break
    elif [[ "$answer" == "no" ]]; then
      echo "Please remove the ~/.config/nvim directory and run the script again."
      exit 1
    else
      echo "Please answer yes or no."
    fi
  done
else
  echo "Creating symbolic links for neovim..."
  /bin/ln -s ~/.local/initial-settings/neovim/nvim-settings ~/.config/nvim
  echo "All done!"
fi

echo "\n"
echo "[IMPORTANT SETTING!!]"
echo "Please run tmux and press:\n\t'F2+Shift+I'\nto install the settings\n"
echo "Please run vim and run:\n\t:MasonInstallAll\nto install the rest of the plugins"
echo "Read the https://github.com/NvChad/NvChad/tree/v2.5 to get more information about nvim settings"
