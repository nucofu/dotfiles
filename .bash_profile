# .bash_profile

# Get the aliases and functions
[ -f $HOME/.bashrc ] && . $HOME/.bashrc

# Ready.. Set, Go! - Specifies to only do startx from tty1
if [[ -z $DISPLAY ]] && [[ $(tty) == /dev/tty1 ]]; then
	exec startx
fi
