#!/bin/bash

#SBATCH -t 12:00:00
#SBATCH -o none

if [ ! -d "${HOME:-~}.ssh" ]; then
    mkdir -p ${HOME:-~}/.ssh
fi

if [ ! -f "${HOME:-~}/.ssh/vscode-remote-hostkey" ]; then
    ssh-keygen -t ed25519 -f ${HOME:-~}/.ssh/vscode-remote-hostkey -N ""
fi

if [ -f "/usr/sbin/sshd" ]; then
    sshd_cmd=/usr/sbin/sshd
else
    sshd_cmd=sshd
fi

$sshd_cmd -D -p $1 -f /dev/null -h ${HOME:-~}/.ssh/vscode-remote-hostkey
