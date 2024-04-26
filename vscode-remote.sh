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

get_running_job(){
    list=($(squeue --me --states=R -h -O JobId:" ",Name:" ",NodeList:" " | grep $JOB_NAME))
    echo ${list[$1]}
}

running_job_id(){
    echo $(get_running_job 0)
}

running_job_port(){
    jobname=$(get_running_job 1)
    split=(${jobname//%/ })
    echo ${split[1]}
}

running_job_node(){
    echo $(get_running_job 2)
}

timeout() {
    if (( $(date +%s)-START > TIMEOUT )); then 
        echo "Timeout, exiting..."
        exit 1
    fi
}

if [ ! -z "$1" ] && [ $1 == "cancel" ]; then
    JOBID=$(running_job_id)
    while [ ! -z "${JOBID}" ]; do
        echo Cancelling job $JOBID
        scancel $JOBID
        timeout
        sleep 2
        JOBID=$(running_job_id)
    done
    exit 0
fi

if [ ! -z "$1" ] && [ $1 == "list" ]; then
    echo $(squeue --me --states=R -O JobId,Partition,Name,User,State,TimeUsed,TimeLimit,NodeList | grep -E "JOBID|$JOB_NAME")
    exit 0
fi

NODE=$(running_job_node)

if [ -z "${NODE}" ]; then
    PORT=$(shuf -i 2000-65000 -n 1)
    /usr/bin/sbatch -J $JOB_NAME%$PORT $SBATCH_PARAM -o none $SCRIPT_DIR/job.sh $PORT

    while [ -z "${NODE}" ]; do
        timeout
        sleep 5
        NODE=$(running_job_node)
    done
fi

echo "Connecting to $NODE"

while ! nc $NODE $(running_job_port); do 
    timeout
    sleep 1 
done