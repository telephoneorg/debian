[ -z "$PS1" ] && return

if [ $TERM != dumb ]
then
    if [ -f "/etc/dircolors" ] ; then
        eval $(dircolors -b /etc/dircolors)

        if [ -f "$HOME/.dircolors" ] ; then
            eval $(dircolors -b $HOME/.dircolors)
        fi
    fi

    c_rst='\[\e[0m\]'
    c_c='\[\e[36m\]'
    c_g='\[\e[92m\]'

    alias ls='ls --color=auto --group-directories-first'
    alias grep='grep --color=auto'
    alias egrep='egrep --color=auto'
    alias fgrep='fgrep --color=auto'
    PS1="${c_c}\$(hostname -s) ${c_g}\W${c_rst} \$ "
else
    alias ls="ls -F --group-directories-first"
    PS1="\$(hostname -s) \W \$ "
fi

unset c_rst c_c c_g
export PS LS_COLORS

