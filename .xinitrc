export XDG_SESSION_TYPE=x11
export XDG_SESSION_CLASS=user
export XDG_RUNTIME_DIR="/run/user/$(id -u)"

# Load Xresources
if [ -f "$HOME/.Xresources" ]; then
    xrdb -merge "$HOME/.Xresources"
fi

# Load Openbox
exec dbus-run-session -- openbox-session
