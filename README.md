# vscode-remote-hpc

A one-click script to setup and connect vscode to a Slurm-based HPC compute node, directly from the VS Code remote explorer. 

## Features
This script is designed to be used with the [Remote - SSH](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh) extension for Visual Studio Code. 

- Automatically starts a batch job, or reuses an existing one, for vscode to connect to.
- No need to manually execute the script on the HPC, just connect from the remote explorer and the script handles everything automagically through `ProxyCommand`.
- Support for two different job types: CPU and GPU

## Requirements
- `sshd` must be available on the compute node, installed in `/usr/sbin` or available in the PATH
- A typical `sshd` installation is required, it must read login keys from `~/.ssh/authorized_keys` 
- You must be allowed to run `sshd` in a batch job on an arbitrary port above 10000, and connect to it from the login node
- The `nc` command (netcat) must be available on the HPC login node
- Compute node names must resolve to their internal IP addresses
- Compute nodes must be accessible via IP from the login node
- You must have SSH access to the HPC login node

These requirements are usually met, except if explicitly changed or forbidden by your system admin.

## Setup

Git clone the repo on the HPC login node (replace `HPC-LOGIN` with your own) and run the installer. 

```shell
ssh HPC-LOGIN
git clone git@github.com:gmertes/vscode-remote-hpc.git
cd vscode-remote-hpc
bash install.sh
```

The script will be installed in `~/bin` and added to your PATH. 

Open the installed script `~/bin/vscode-remote` with your favourite editor and edit the `SBATCH_PARAM_CPU` and `SBATCH_PARAM_GPU` parameters at the top according to your Slurm system. It is recommended to keep the job time (`-t`) to a reasonable amount. The script expects that jobs get automatically killed when they reach their wall clock time. 

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
Host vscode-remote-cpu
    User USERNAME
    IdentityFile ~/.ssh/vscode-remote
    ProxyCommand ssh HPC-LOGIN "~/bin/vscode-remote cpu"
    StrictHostKeyChecking no
```

You can change `vscode-remote cpu` to `vscode-remote gpu` to start a GPU job.

## Usage
The `vscode-remote-cpu` host is now available in the VS Code remote explorer. Connecting to this host will automatically launch a batch job on a CPU node, wait for it to start, and connect to the node when the job is running.

Running jobs are automatically reused. If a running job is already found, it will simply connect to it. You can safely open many remote windows and they will all share the same running job. 

Note that disconnecting the remote session in vscode will **not** kill the job on the HPC. You can close the remote window and the job will keep running. Jobs are expected to be automatically killed by the Slurm scheduler when they reach their wall clock time. You can manually kill the job using `scancel` or with the `vscode-remote cancel` command (see [CLI](#CLI)).

You can have one CPU and one GPU job running at the same time, just add a new entry in your `~/.ssh/config` for the GPU job:

```bash
Host vscode-remote-gpu
    User USERNAME
    IdentityFile ~/.ssh/vscode-remote
    ProxyCommand ssh HPC-LOGIN "~/bin/vscode-remote gpu"
    StrictHostKeyChecking no
```

## CLI
The `vscode-remote` command installed on your HPC offers some commands to list or cancel running jobs. Do `vscode-remote help` for help on its usage.

```bash
$ vscode-remote help
Usage :  ~/bin/vscode-remote [command]

    General commands:
    list      List running vscode-remote jobs
    cancel    Cancels running vscode-remote jobs
    ssh       SSH into the node of a running job
    help      Display this message
```