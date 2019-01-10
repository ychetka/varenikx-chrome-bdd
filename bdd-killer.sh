#!/bin/bash

KILLER_LOG_FILE=$1

NODE_PIDS=$(pgrep node)
SOCAT_PIDS=$(pgrep socat)

echo "START KILL..." > ${KILLER_LOG_FILE}

for PID in ${NODE_PIDS}
do
    kill ${PID} >> ${KILLER_LOG_FILE} &
done

for PID in ${SOCAT_PIDS}
do
    kill ${PID} >> ${KILLER_LOG_FILE} &
done

exit 0
