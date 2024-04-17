JOB_NAME=gert-vscode

#########
JOB_NAME=${JOB_NAME//%/-}
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

get_running_job(){
    list=($(ecsqueue --me --states=R -h -O JobId:" ",Name:" ",NodeList:" " | grep $JOB_NAME))
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

if [ ! -z "$1" ] && [ $1 == "cancel" ]; then
    JOBID=$(running_job_id)
    while [ ! -z "${JOBID}" ]
    do
        echo Cancelling job $JOBID
        ecscancel $JOBID
        JOBID=$(running_job_id)
    done
    exit 0
fi

if [ ! -z "$1" ] && [ $1 == "list" ]; then
    output=$(ecsqueue --me --states=R -O JobId,Partition,Name,User,State,TimeUsed,TimeLimit,NodeList | grep -E "JOBID|$JOB_NAME")
    echo "$output"
    exit 0
fi

NODE=$(running_job_node)

if [ -z "${NODE}" ]; then
    PORT=$(shuf -i 2000-65000 -n 1)
    /usr/bin/sbatch -J $JOB_NAME%$PORT $SCRIPT_DIR/cpu-job.sh $PORT
fi

while [ -z "${NODE}" ]
do
    sleep 2
    NODE=$(running_job_node)
done

echo "Connecting to $NODE"

while ! nc $NODE $(running_job_port) ; do sleep 1 ; done