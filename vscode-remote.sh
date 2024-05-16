#!/bin/bash

# Set your Slurm parameters for GPU and CPU jobs here
SBATCH_PARAM_CPU="-q ni -t 12:00:00 --mem=32G -c 8"
SBATCH_PARAM_GPU="-q ng --gpus=1 -t 04:00:00 --mem=32G -c 8"

# The time you expect a job to start in (seconds)
# If a job doesn't start within this time, the script will exit and cancel the pending job
TIMEOUT=300


####################
# don't edit below this line
####################

function usage ()
{
    echo "Usage :  $0 [command]

    General commands:
    list      List running vscode-remote job
    cancel    Cancels running vscode-remote job
    ssh       SSH into the node of a running job
    help      Display this message

    Job commands (see usage below):
    cpu       Connect to a CPU node
    gpu       Connect to a GPU node

    You should not manually call the script with 'cpu' or 'gpu' commands.
    They should be used in the ProxyCommand in your ~/.ssh/config file, for example:
        Host vscode-remote-cpu
            User USERNAME
            IdentityFile ~/.ssh/vscode-remote
            ProxyCommand ssh HPC-LOGIN \"bash --login -c 'vscode-remote cpu'\"
            StrictHostKeyChecking no  

    You can only have one job type at a time (cpu or gpu). If you want to switch job types, you have to first run 'cancel'.
    "
} 

function query_slurm () {
    # only list states that can result in a running job
    list=($(squeue --me --states=R,PD,S,CF,RF,RH,RQ -h -O JobId:" ",Name:" ",State:" ",NodeList:" " | grep $JOB_NAME))

    if [ ! ${#list[@]} -eq 0 ]; then
        JOB_ID=${list[0]}
        JOB_FULLNAME=${list[1]}
        JOB_STATE=${list[2]}
        JOB_NODE=${list[3]}

        split=(${JOB_FULLNAME//%/ })
        JOB_PORT=${split[1]}

        >&2 echo "Job is $JOB_STATE ( id: $JOB_ID, name: $JOB_FULLNAME${JOB_NODE:+, node: $JOB_NODE} )" 
    else
        JOB_ID=""
        JOB_FULLNAME=""
        JOB_STATE=""
        JOB_NODE=""
        JOB_PORT=""
    fi
}

function cleanup () {
    if [ ! -z "${JOB_SUBMIT_ID}" ]; then
        scancel $JOB_SUBMIT_ID
        >&2 echo "Cancelled pending job $JOB_SUBMIT_ID"
    fi
}

function timeout () {
    if (( $(date +%s)-START > TIMEOUT )); then 
        >&2 echo "Timeout, exiting..."
        cleanup
        exit 1
    fi
}

function cancel () {
    query_slurm > /dev/null 2>&1
    while [ ! -z "${JOB_ID}" ]; do
        echo "Cancelling running job $JOB_ID on $JOB_NODE"
        scancel $JOB_ID
        timeout
        sleep 2
        query_slurm > /dev/null 2>&1
    done
}

function list () {
    width=$((${#JOB_NAME} + 11))
    echo "$(squeue --me -O JobId,Partition,Name:$width,State,TimeUsed,TimeLimit,NodeList | grep -E "JOBID|$JOB_NAME")"
}

function ssh_connect () {
    query_slurm
    if [ -z "${JOB_NODE}" ]; then
        echo "No running job found"
        exit 1
    fi
    echo "Connecting to $JOB_NODE via SSH"
    ssh $JOB_NODE
}

function connect () {
    query_slurm

    if [ -z "${JOB_STATE}" ]; then
        PORT=$(shuf -i 10000-65000 -n 1)
        list=($(/usr/bin/sbatch -J $JOB_NAME%$PORT $SBATCH_PARAM $SCRIPT_DIR/vscode-remote-job.sh $PORT))
        JOB_SUBMIT_ID=${list[3]}
        >&2 echo "Submitted new $JOB_NAME job (id: $JOB_SUBMIT_ID)"
    fi

    while [ ! "$JOB_STATE" == "RUNNING" ]; do
        timeout
        sleep 5
        query_slurm
    done

    >&2 echo "Connecting to $JOB_NODE"

    while ! nc -z $JOB_NODE $JOB_PORT; do 
        timeout
        sleep 1 
    done

    nc $JOB_NODE $JOB_PORT
}

if [ ! -z "$1" ]; then
    JOB_NAME=vscode-remote
    SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
    START=$(date +%s)
    trap "cleanup && exit 1" INT TERM
    case $1 in
        list)   list ;;
        cancel) cancel ;;
        ssh)    ssh_connect ;;
        cpu)    JOB_NAME=$JOB_NAME-cpu; SBATCH_PARAM=$SBATCH_PARAM_CPU; connect ;;
        gpu)    JOB_NAME=$JOB_NAME-gpu; SBATCH_PARAM=$SBATCH_PARAM_GPU; connect ;;
        help)   usage ;;
        *)  echo -e "Command '$1' does not exist" >&2
            usage; exit 1 ;;
    esac  
    exit 0
else
    usage
    exit 0
fi
