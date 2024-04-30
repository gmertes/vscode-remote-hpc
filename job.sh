#!/bin/bash

#SBATCH -o none

/usr/sbin/sshd -D -p $1 -f /dev/null -h ${HOME}/.ssh/id_ed25519
