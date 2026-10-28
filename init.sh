# Fix up the git repository, from wherever it was cloned:
cp -r $(pwd)/ $HOME/.config/

# Create env files:
echo 'export XDG_CONFIG_HOME="$HOME/.config"' > $HOME/.zshenv
echo 'export ZDOTDIR="$XDG_CONFIG_HOME/zsh"' >> $HOME/.zshenv
 
# Install Homebrew: 
sh -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Oh-My-Zsh:
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install zsh-syntax-highlighting:
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# powerlevel10k:
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# Vim Plug (Neovim link):
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

# Install brew packages:
brew install go nvim helm jq derailed/k9s/k9s awscli

# Download and setup Java
sh ./installJava.sh
