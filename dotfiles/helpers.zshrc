alias used_ports="sudo lsof -i -n -P | grep LISTEN"
export MANPAGER='nvim +Man!'
export TERM=xterm-256color
defaults write -g InitialKeyRepeat -int 10
defaults write -g KeyRepeat -int 2
alias gs="git add . && git commit -m \"scratch\""
alias dwnmp4='aria2c -x 16 -s 16 -d ~/Downloads'
alias setup_python='python3 -m venv venv && source ./venv/bin/activate'
