#!/bin/bash

set -e

ZSH_PLUGINS="$HOME/.oh-my-zsh/custom/plugins"
ZSH_THEMES="$HOME/.oh-my-zsh/custom/themes"

mkdir -p ./backups

sudo apt install -y zsh git fonts-font-awesome > /dev/null


if [ ! -d ~/.oh-my-zsh ];
then

  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --keep-zshrc --unattended

  cp $HOME/.zshrc ./backups/.zshrc.bak

fi

if [ ! -d $ZSH_PLUGINS/zsh-autosuggestions ];
then

  echo "Cloning zsh-users/zsh-autosuggestions..."

  git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_PLUGINS/zsh-autosuggestions > /dev/null

fi

if [ ! -d $ZSH_PLUGINS/zsh-completions ];
then

  echo "Cloning zsh-users/zsh-completions..."

  git clone https://github.com/zsh-users/zsh-completions $ZSH_PLUGINS/zsh-completions

fi

if [ ! -d $ZSH_PLUGINS/zsh-syntax-highlighting ];
then

  echo "Cloning zsh-users/zsh-syntax-highlighting..."

  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_PLUGINS/zsh-syntax-highlighting

fi

if ! grep --quiet "plugins=(git zsh-autosuggestions zsh-syntax-highlighting)" $HOME/.zshrc;
then

  echo "Adding zsh plugins..."

  findPlugins="plugins=(git)"
  replacePlugins="plugins=(git zsh-autosuggestions zsh-syntax-highlighting)"
  replaceFpath="fpath+=$ZSH_PLUGINS/zsh-completions/src"
  replaceExport="export ZSH=\"\$HOME/.oh-my-zsh\""
  
  sed --in-place "s,$replaceExport,,g" $HOME/.zshrc

  sed --in-place "s,$findPlugins,$replacePlugins\n$replaceFpath\n$replaceExport,g" $HOME/.zshrc

else

  echo "Already added zsh plugins."

fi

if [ ! -d $ZSH_THEMES/powerlevel10k ];
then

  echo "Cloning romkatv/powerlevel10k..."

  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $ZSH_THEMES/powerlevel10k

fi

if ! grep --quiet "ZSH_THEME=\"powerlevel10k/powerlevel10k\"" $HOME/.zshrc;
then

  echo "Changing ZSH_THEME to powerlevel10k..."

  findTheme="ZSH_THEME=\"robbyrussell\""
  replaceTheme="ZSH_THEME=\"powerlevel10k/powerlevel10k\""
  
  sed --in-place "s,$findTheme,$replaceTheme,g" $HOME/.zshrc

else

  echo "ZSH_THEME is already powerlevel10k."

fi

if ! grep --quiet "$USER.*$( which zsh )" /etc/passwd;
then

  echo "Updating default shell for $USER to zsh..."
  
  chsh --shell $(which zsh)

else

  echo "Already updated default shell to zsh for $USER."

fi