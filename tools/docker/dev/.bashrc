# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
  . /etc/bashrc
fi

# Expand terminal history size
export HISTSIZE=99999

alias vi=vim
alias ls='ls --color'

#
# Define git prompt and git completion
#
source /usr/share/doc/git/contrib/completion/git-prompt.sh
source /usr/share/doc/git/contrib/completion/git-completion.bash

# Configure `__git_ps1` to tell us as much as possible
export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWSTASHSTATE=1
export GIT_PS1_SHOWUPSTREAM=verbose
export GIT_PS1_SHOWUNTRACKEDFILES=1
export GIT_PS1_SHOWCONFLICTSTATE=yes
export GIT_PS1_DESCRIBE_STYLE=branch
export GIT_PS1_SHOWCOLORHINTS=1
export GIT_PS1_HIDE_IF_PWD_IGNORED=1

# Trim path to 3 dirs
export PROMPT_DIRTRIM=3

# Control the prompt
# https://www.gnu.org/software/bash/manual/html_node/Controlling-the-Prompt.html
# Color and formatting
# https://misc.flogisoft.com/bash/tip_colors_and_formatting
#
PS1=""
PS1+="\[\e[90m\]" # light gray
PS1+="\u@\h" # user
PS1+="\[\e[38;5;214m\]" # dark yellow
PS1+=" \w" # path
PS1+="\[\e[0;94m\]" # blue
PS1+='$(__git_ps1 " (%s)")' # git info
PS1+="\[\e[0m\]" # reset formatting (white)
PS1+=" \$ " # prompt
export PS1
