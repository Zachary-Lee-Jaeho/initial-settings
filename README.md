# Jaeho's Initial Settings (JIS)
for NEOVIM and TMUX

> First, install zsh!
> 
> I'd like you to please feel free to open the issue when you find some bugs.

# How to install 

Run the following command to install the settings

``` bash
git clone https://github.com/Zachary-Lee-Jaeho/initial-settings.git ~/.local/initial-settings
cd ~/.local/initial-settings
zsh ./setup.sh
```

- Works on Ubuntu/Debian (apt) and macOS (Homebrew; the script offers to install it).
- Pick the components by number: prerequisites, zsh (oh-my-zsh), tmux, neovim.
- Neovim is updated to the latest stable release on every run
  (Linux: official tarball unpacked into `neovim/`, macOS: Homebrew).
- An existing `~/.tmux.conf` or `~/.config/nvim` is backed up before it is replaced.
- The repo can live anywhere; the links point to wherever you cloned it.
- Command output goes to `~/.cache/jis/setup-<timestamp>.log`.
