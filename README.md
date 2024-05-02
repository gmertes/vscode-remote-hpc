# vscode-remote-hpc

A one-click script to setup and connect vscode to a Slurm-based HPC compute node directly from the remote explorer. 

## Features
- Automatically starts a batch job, or reuses an existing one, for vscode to connect to.
- No need to manually execute the script on the HPC, just connect from the remote explorer and the script handles everything automagically through `ProxyCommand`.

## Setup

Git clone the repo on the HPC (replace `HPC-LOGIN` with your own) and make the `vscode-remote.sh` script executable. Also create an alias to easily execute the script.

```shell
ssh HPC-LOGIN
cd ~
git clone git@github.com:gmertes/vscode-remote-hpc.git
chmod +x ~/vscode-remote-hpc/vscode-remote.sh
echo 'alias vscode-remote="~/vscode-remote-hpc/vscode-remote.sh"' >> ~/.bashrc
```

On your local machine, generate a new ssh key for vscode-remote:

```shell
ssh-keygen -f ~/.ssh/vscode-remote -t ed25519 -N ""
```

Copy the public key to your HPC `authorized_hosts`, you can use `ssh-copy-id`:

```shell
ssh-copy-id -i ~/.ssh/vscode-remote HPC-LOGIN
```

In VS Code, change the `remote.SSH.connectTimeout` setting. Set this to the maximum time in seconds you expect a new job to start on your HPC. The script default is `300`.

```yaml
"remote.SSH.connectTimeout": 300
```

Add the following entry to your local machine's `~/.ssh/config`. Change `USERNAME` and `HPC-LOGIN` accordingly:

```bash
Host vscode-remote
    User USERNAME
    IdentityFile ~/.ssh/vscode-remote
    ProxyCommand ssh HPC-LOGIN "~/vscode-remote-hpc/vscode-remote.sh"
    StrictHostKeyChecking no
```

## Usage
The `vscode-remote` host is now available in the VS Code remote explorer. Connecting to this host will automatically launch a batch job and connect to the compute node.