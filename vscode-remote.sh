#!/bin/bash

JOB_NAME=vscode-remote
TIMEOUT=300

if [ ! -z "$1" ] && [ $1 == "gpu" ]; then
    SBATCH_PARAM="-q ng --gpus=1 -t 04:00:00 --mem=32G -c 16"
else
    SBATCH_PARAM="-q ni -t 12:00:00 --mem=32G -c 16"
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
START=$(date +%s)

query_job(){
    list=($(squeue --me --states=R -h -O JobId:" ",Name:" ",NodeList:" " | grep $JOB_NAME))
    if [ ! ${#list[@]} -eq 0 ]; then
        JOB_ID=${list[0]}
        JOB_FULLNAME=${list[1]}
        JOB_NODE=${list[2]}

        split=(${JOB_FULLNAME//%/ })
        JOB_PORT=${split[1]}
    else
        JOB_ID=""
        JOB_FULLNAME=""
        JOB_NODE=""
        JOB_PORT=""
    fi
}

timeout() {
    if (( $(date +%s)-START > TIMEOUT )); then 
        echo "Timeout, exiting..."
        exit 1
    fi
}

if [ ! -z "$1" ] && [ $1 == "cancel" ]; then
    query_job
    while [ ! -z "${JOB_ID}" ]; do
        echo Cancelling job $JOB_ID
        scancel $JOB_ID
        timeout
        sleep 2
        query_job
    done
    exit 0
fi

if [ ! -z "$1" ] && [ $1 == "list" ]; then
    echo "$(squeue --me --states=R -O JobId,Partition,Name,UserName,State,TimeUsed,TimeLimit,NodeList | grep -E "JOBID|$JOB_NAME")"
    exit 0
fi

query_job

if [ -z "${JOB_NODE}" ]; then
    PORT=$(shuf -i 2000-65000 -n 1)
    /usr/bin/sbatch -J $JOB_NAME%$PORT $SBATCH_PARAM -o none $SCRIPT_DIR/job.sh $PORT

    while [ -z "${JOB_NODE}" ]; do
        timeout
        sleep 5
        query_job
    done
fi

echo "Connecting to $JOB_NODE"

while ! nc $JOB_NODE $JOB_PORT; do 
    timeout
    sleep 1 
done