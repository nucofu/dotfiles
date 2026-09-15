# .bashrc

# Binary PATH Location
#export PATH="/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin:~/Documents/Manual_App/portable"
export PATH="/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin"

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Timezone
export TZ=Asia/Jakarta

PS1="[\[\e[1;35m\]\u\[\e[m\]@\[\e[1;32m\]\h\[\e[m\]] - [\[\e[0;31m\]\w\[\e[m\]]\n-> "

# sudo completation
if [ "$PS1" ]; then
	complete -cf sudo
fi

# alias
alias ssha='eval $(ssh-agent) && ssh-add'
alias ls='ls --color=auto'

# env configuration
QT_QPA_PLATFORMTHEME=qt5ct

# Python Version Management
#export PYENV_ROOT="$HOME/.pyenv"
#[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
#eval "$(pyenv init - bash)"

# Npm Version Management
#export NVM_DIR="$HOME/.nvm"
#[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
#[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
