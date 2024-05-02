#!/bin/bash

#SBATCH -o none

if [ ! -d "${HOME:-~}.ssh" ]; then
    mkdir -p ${HOME:-~}/.ssh
fi

if [ ! -f "${HOME:-~}/.ssh/vscode-remote-hostkey" ]; then
    ssh-keygen -t ed25519 -f ${HOME:-~}/.ssh/vscode-remote-hostkey -N ""
fi

/usr/sbin/sshd -D -p $1 -f /dev/null -h ${HOME:-~}/.ssh/vscode-remote-hostkey
