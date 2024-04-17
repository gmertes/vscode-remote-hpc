#!/bin/bash

#SBATCH --mem=32G
#SBATCH -c 8
#SBATCH -q ni
#SBATCH -t 12:00:00
#SBATCH -o none

/usr/sbin/sshd -D -p $1 -f /dev/null -h ${HOME}/.ssh/id_ed25519
