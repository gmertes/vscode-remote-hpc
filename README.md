# vscode-remote-hpc

A one-click script to setup and connect vscode to a Slurm-based HPC compute node directly from the remote explorer. 

## Features
- Automatically starts a batch job, or reuses an existing one, for vscode to connect to.
- No need to manually execute the script on the HPC, just connect from the remote explorer and the script handles everything automagically through `ProxyCommand`.

## Setup