#!/bin/bash

KILLER_LOG_FILE=

if [ -n "${1}" ]; then
  KILLER_LOG_FILE=$1
else
  KILLER_LOG_FILE="/dev/null"
fi

NODE_PIDS=$(pgrep node)
SOCAT_PIDS=$(pgrep socat)

echo "START KILL..." > ${KILLER_LOG_FILE}

for NPID in ${NODE_PIDS}
do
    echo "KILL ${NPID}" >> ${KILLER_LOG_FILE}
    kill ${NPID} >> ${KILLER_LOG_FILE} &
done

for SPID in ${SOCAT_PIDS}
do
    echo "KILL ${SPID}" >> ${KILLER_LOG_FILE}
    kill ${SPID} >> ${KILLER_LOG_FILE} &
done

echo "KILL COMPLETED" >> ${KILLER_LOG_FILE}

exit 0
