#!/bin/bash

#$1 - GIT data
#'{"repository":"aaa..","token":"bbb...","pullRequestId":"ccc...","branch":"ddd..."}'

#$2 - threads JSON - support tags and groups
#[
#  "./features/_demos",
#  "./features/_service",
#  "./features/_web/ui/builder",
#  "./features/_web/ui/contents",
#  "./features/_web/ui/dashboard",
#  "./features/_web/ui/module",
#  "./features/_web/ui/others",
#  "./features/_web/ui/view"
#]

#$3 - tags for all threads
# (not @bug) and (not @for_future_use) and (not @excluded_from_bdd) and (not @blank)

#$4 api hosts for threads
# '["bdd1.optimacros.com", "bdd1.optimacros.com", "bdd2.optimacros.com", "bdd2.optimacros.com", "bdd3.optimacros.com"]'

#$5 - rerun
# boolean

#$6 - skip git, server and compile
# boolean


#EXAMPLE
#~/git-bdd-runner-parallel.sh '{"repository":"optimacros/optimacros_frontend","token":"517f7a241b07cbe16dfa20e6c0902076962802da","pullRequestId":"122","branch":"OM-727"}' '["tags:@service and not @bug", "tags:@service and not @bug", "tags:@service and not @bug", "tags:@service and not @bug", "tags:@service and not @bug"]' '["bdd1.optimacros.com", "bdd1.optimacros.com", "bdd2.optimacros.com", "bdd2.optimacros.com", "bdd3.optimacros.com"]'

export DEBUG=0

GIT=$1
FEATURES=$2
ALL_THREADS_TAGS=$3
WORKSPACES=$4
WITH_RERUNS=$5
SKIP_GET_AND_COMPILE=$6

LOCAL_INTERFACE_IP="127.0.0.1"
EXTERNAL_INTERFACE_IP="95.216.44.235"

ROOT_ID=$(uuidgen)
ABSOLUTE_REPORT_DIRECTORY="$HOME/src/reports"
ARCHIVE_REPORT_DIRECTORY="$HOME/reports"
THREADS_COUNT=$(echo ${FEATURES} | jq -r '. | length')
let LAST_THREAD_INDEX=$THREADS_COUNT-1
THREAD_IDS=( )
THREAD_START_TIMES=( )
THREAD_END_TIMES=( )
THREAD_WORKSPACES=( )
THREAD_GROUPS=( )
THREAD_DIRS=( )
THREAD_LOGS=( )
THREAD_RERUNS=( )
THREADS_RERUN_FEATURE_LOGS=( )
THREAD_DEBUG_PORTS=( )

#./initenv.sh
PROJECT_NODE_VERSION="v9.4.0"
source ~/.nvm/nvm.sh &> /dev/null
nvm install ${PROJECT_NODE_VERSION} &> /dev/null
nvm use ${PROJECT_NODE_VERSION} &> /dev/null
nvm alias default ${PROJECT_NODE_VERSION} &> /dev/null
npm install yarn -g &> /dev/null

#$1 INTERFACE IP
function getEmptyInterfacePort(){
    INTERFACE=$1
    LPORT=32768;
    UPORT=60999;
    while true; do
        MPORT=$[$LPORT + ($RANDOM % $UPORT)];
        (echo "" >/dev/tcp/${INTERFACE}/${MPORT}) >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo $MPORT;
            return 0;
        fi
    done
}

#$1 local interface port
#$2 external interface port
#$3 id
function forwardLocalPortToExternalPort(){
    local LOCAL_PORT=$1
    local EXTERNAL_PORT=$2
    local THREAD_ID=$3

    socat tcp-listen:${EXTERNAL_PORT},fork tcp:${LOCAL_INTERFACE_IP}:${LOCAL_PORT} > "${ABSOLUTE_REPORT_DIRECTORY}/${THREAD_ID}_debug_port_${EXTERNAL_PORT}.log" &
}

function killAllThreads {
  sudo $HOME/bdd-killer.sh "${ABSOLUTE_REPORT_DIRECTORY}/killer.log" &

  sleep 20

  sudo $HOME/bdd-killer.sh "${ABSOLUTE_REPORT_DIRECTORY}/killer.log" &

  sleep 10
}

function printCompletedState {

  for index in $(seq 0 ${LAST_THREAD_INDEX})
    do
      threadId=${THREAD_IDS[$index]}
      threadStatus=$(sqlite3 -init <(echo ".timeout 3000") ${ABSOLUTE_REPORT_DIRECTORY}/test.db  "SELECT STATUS FROM THREAD_STATUSES WHERE THREAD_ID ='${threadId}' LIMIT 1")

      if (( ${threadStatus} == "0" )); then
        threadStartTime=${THREAD_START_TIMES[$index]}
        threadEndTime=${THREAD_END_TIMES[$index]}
        threadRerunsLog=${THREADS_RERUN_FEATURE_LOGS[$index]}

        if [ -z "$threadRerunsLog" ]
          then
           echo -e "\x1b[5;42;37m:THREAD ${threadId} ${THREAD_GROUPS[$index]} COMPLETED. WAS START:${threadStartTime} END:${threadEndTime}.\x1b[0m"
          else
           echo -e "\x1b[5;42;37m:THREAD ${threadId} ${THREAD_GROUPS[$index]} COMPLETED WITH RERUNS. WAS START:${threadStartTime} END:${threadEndTime}.\x1b[0m"
           echo -e "\x1b[37;43m:THREAD RERUNS ${threadRerunsLog} \x1b[0m"
        fi
      fi
  done
}

function printFailedState {
  for index in $(seq 0 ${LAST_THREAD_INDEX})
  do
    threadId=${THREAD_IDS[$index]}
    threadStatus=$(sqlite3 -init <(echo ".timeout 3000") ${ABSOLUTE_REPORT_DIRECTORY}/test.db  "SELECT STATUS FROM THREAD_STATUSES WHERE THREAD_ID ='${threadId}' LIMIT 1")

    if (( ${threadStatus} == "1" )); then
       echo -e "\x1b[5;41;37mFAILED ${THREAD_GROUPS[$index]} \x1b[0m"
    fi
    sleep 5
  done
}

function failedCompile {
  echo -e "\x1b[5;41;37mFAILED COMPILE PROJECT!\x1b[0m"
  exit 1
}

#$1 rerun file patch
function _getRerunLines {
  cat "${1}" | while read line || [ -n "$line" ];
  do
      feature=$(echo "${line}"| cut -d':' -f 1);
      echo "${feature} "
  done
}

function parseRerunFile {
  echo $(_getRerunLines $1)
}

#$1 thead index
#$2 thead rerun number
function rerunFailedThreads {
THREAD_STATE=2
THREAD_RERUN_NUMBER=$2
RERUN_PATCH="${ABSOLUTE_REPORT_DIRECTORY}/${THREAD_IDS[$1]}.rerun.txt"
THREAD_RERUN_FEATURES=${THREAD_GROUPS[$1]}
THREAD_LOG="${ABSOLUTE_REPORT_DIRECTORY}/${THREAD_IDS[$1]}.rerun.${THREAD_RERUN_NUMBER}.stdout.txt"

if [ -f "${RERUN_PATCH}" ]; then
  #generate THREAD_GROUPS from rerun file
  THREAD_RERUN_FEATURES="$(parseRerunFile ${RERUN_PATCH})"
fi

if [ -z "$THREAD_RERUN_FEATURES" ]; then
  THREAD_RERUN_FEATURES=${THREAD_GROUPS[$1]}
fi

#THREAD_RERUN_FEATURES может содержать как пути для filters так и tags
if ($(echo ${THREAD_RERUN_FEATURES} | grep -q '^tags:')); then
  #tags
  THREAD_GROUPS[$1]=${THREAD_RERUN_FEATURES}
  else
  THREAD_GROUPS[$1]="filter:${THREAD_RERUN_FEATURES} --tags '${ALL_THREADS_TAGS}'"
fi

echo -e '\E[37;44m'"\033[1mWILL RERUN ${THREAD_GROUPS[$1]}. DEBUG AT ${THREAD_DEBUG_PORTS[$1]} \033[0m"

sqlite3 -init <(echo ".timeout 3000") ${ABSOLUTE_REPORT_DIRECTORY}/test.db "UPDATE THREAD_STATUSES SET STATUS= '2' WHERE THREAD_ID= '${THREAD_IDS[$1]}';"
THREADS_RERUN_FEATURE_LOGS[$index]="${THREADS_RERUN_FEATURE_LOGS[$index]} ${THREAD_GROUPS[$1]}"

if (( DEBUG == "1" )); then
    echo "Call file-bdd-runner with ${THREAD_GROUPS[$1]}"
fi

~/file-bdd-runner.sh "${HOME}/src" "${THREAD_GROUPS[$1]}" "${THREAD_IDS[$1]}" "${THREAD_WORKSPACES[$1]}" "${ABSOLUTE_REPORT_DIRECTORY}" "${THREAD_DEBUG_PORTS[$1]}" > "${THREAD_LOG}" &

sleep 3
}

#cd $HOME

############## INIT GIT
if [ -z "$SKIP_GET_AND_COMPILE" ]
  then
    ~/git-worker.sh "$GIT" "$HOME/src" && ~/yarn-worker.sh "$HOME/src" "/dev/null" || failedCompile
  else
  #skip compile
    echo -e "\x1b[5;41;37m SKIP GET FROM REPOSITORY, SKIP COMPILE PROJECT \x1b[0m"
fi

# run server
if (( DEBUG == "1" )); then
    echo "SERVER LOG: ${ABSOLUTE_REPORT_DIRECTORY}/server.log"
fi

~/server-worker.sh "${ABSOLUTE_REPORT_DIRECTORY}/server.log" &

if [ ! -d "${ABSOLUTE_REPORT_DIRECTORY}" ]; then
  mkdir "${ABSOLUTE_REPORT_DIRECTORY}"
  chmod 0777 "${ABSOLUTE_REPORT_DIRECTORY}"

  else

  rm -r ${ABSOLUTE_REPORT_DIRECTORY}
  mkdir "${ABSOLUTE_REPORT_DIRECTORY}"
  chmod 0777 "${ABSOLUTE_REPORT_DIRECTORY}"
fi

echo -e "\x1b[5;42;37m*** BUILD ID  $ROOT_ID ***\x1b[0m"
echo -e "\x1b[5;42;37m:WILL RUN $THREADS_COUNT THREADS WITH TIMEOUT 120 MINUTES\x1b[0m"

sqlite3 -init <(echo ".timeout 3000") ${ABSOLUTE_REPORT_DIRECTORY}/test.db  "CREATE TABLE THREAD_STATUSES (ID INTEGER PRIMARY KEY AUTOINCREMENT, THREAD_ID TEXT,STATUS TEXT,SHOW_STATUS TEXT);"

############## START THREADS

for i in $(seq 0 ${LAST_THREAD_INDEX})
  do
    THREAD_ID=$(uuidgen)
    THREAD_LOG="${ABSOLUTE_REPORT_DIRECTORY}/${THREAD_ID}.stdout.txt"
    THREAD_GROUP=$(echo ${FEATURES} | jq -r '.['${i}']')

    if ($(echo ${THREAD_GROUP} | grep -q '^tags:')); then
      #tags
      THREAD_GROUP="${THREAD_GROUP} and ${ALL_THREADS_TAGS}"
    else
      if ($(echo ${THREAD_GROUP} | grep -q '^filter')); then
        THREAD_GROUP="${THREAD_GROUP} --tags '${ALL_THREADS_TAGS}'"
      fi
    fi

    THREAD_WORKSPACE=$(echo ${WORKSPACES} | jq -r '.['${i}']')
    THREAD_STATE=2
    THREAD_RERUN=5
    THREAD_START_TIME=$(date +"%T")
    THREAD_DEBUG_PORT=$(getEmptyInterfacePort ${EXTERNAL_INTERFACE_IP})
    THREAD_IDS=( "${THREAD_IDS[@]}" "$THREAD_ID" )
    THREAD_LOGS=( "${THREAD_LOGS[@]}" "$THREAD_LOG" )
    THREAD_GROUPS=( "${THREAD_GROUPS[@]}" "$THREAD_GROUP" )
    THREAD_WORKSPACES=( "${THREAD_WORKSPACES[@]}" "$THREAD_WORKSPACE" )
    THREAD_RERUNS=( "${THREAD_RERUNS[@]}" "$THREAD_RERUN" )
    THREAD_START_TIMES=( "${THREAD_START_TIMES[@]}" "$THREAD_START_TIME" )
    THREAD_DEBUG_PORTS=( "${THREAD_DEBUG_PORTS[@]}" "$THREAD_DEBUG_PORT" )

    sqlite3 -init <(echo ".timeout 3000") ${ABSOLUTE_REPORT_DIRECTORY}/test.db  "INSERT INTO THREAD_STATUSES (THREAD_ID,STATUS,SHOW_STATUS) values ('${THREAD_ID}','${THREAD_STATE}','true');"
    THREADS_RERUN_FEATURE_LOGS[$index]=""
    echo -e '\E[37;44m'"\033[1m:RUN THREAD $THREAD_GROUP with id: $THREAD_ID at $THREAD_WORKSPACE. DEBUG AT ${THREAD_DEBUG_PORT} \033[0m"

    threadLocalPort=$(getEmptyInterfacePort ${LOCAL_INTERFACE_IP})

    forwardLocalPortToExternalPort ${threadLocalPort} ${THREAD_DEBUG_PORT} ${THREAD_ID}

    ~/file-bdd-runner.sh "${HOME}/src" "${THREAD_GROUP}" "${THREAD_ID}" "${THREAD_WORKSPACE}" "${ABSOLUTE_REPORT_DIRECTORY}" "${THREAD_DEBUG_PORT}" > "${THREAD_LOG}" &

    sleep 3
done

############## WATCH THREADS ##############
# 120 minutes
for i in $(seq 1 120)
do

#ckeck timeout
if (( "${i}" == "119" )); then
  echo -e "\x1b[5;41;37m:::ABORT BY TIMEOUT !!! \x1b[0m"
  exit 1
fi

THREAD_STATUSES=( )
THREAD_SHOW_STATUSES=( )

for index in $(seq 0 ${LAST_THREAD_INDEX})
  do
    threadId=${THREAD_IDS[$index]}
    THREAD_STATUSES[$index]=$(sqlite3 -init <(echo ".timeout 3000") ${ABSOLUTE_REPORT_DIRECTORY}/test.db  "SELECT STATUS FROM THREAD_STATUSES WHERE THREAD_ID ='${threadId}' LIMIT 1")
    THREAD_SHOW_STATUSES[$index]=$(sqlite3 -init <(echo ".timeout 3000") ${ABSOLUTE_REPORT_DIRECTORY}/test.db  "SELECT SHOW_STATUS FROM THREAD_STATUSES WHERE THREAD_ID ='${threadId}' LIMIT 1")
done

# check all completed
if [ -z "$(echo ${THREAD_STATUSES[*]} | grep '2')" ]; then

    if (( DEBUG == "1" )); then
        echo "NOT EXIST THREADS WITH STATUS 2!"
    fi

    if [ -z "$(echo ${THREAD_STATUSES[*]} | grep '1')" ]; then
#       all threads ok

        printCompletedState

        echo -e "\x1b[5;42;37m###########################################################\x1b[0m"
        echo -e "\x1b[5;42;37m:::ALL THREADS BDD COMPLETED !!! \x1b[0m"
        echo -e "\x1b[5;42;37m###########################################################\x1b[0m"

#       copy to reports archive

        if (( DEBUG == "1" )); then
            echo "!!!REPORTS"
            echo "CREATE ${ARCHIVE_REPORT_DIRECTORY}/${ROOT_ID}"
        fi

        mkdir "${ARCHIVE_REPORT_DIRECTORY}/${ROOT_ID}" > /dev/null

        if (( DEBUG == "1" )); then
            echo "CHMOD 0775 ${ARCHIVE_REPORT_DIRECTORY}/${ROOT_ID}"
        fi

        chmod 0755 ${ARCHIVE_REPORT_DIRECTORY}/${ROOT_ID} > /dev/null

        if (( DEBUG == "1" )); then
            echo "COPY REPORTS ${ABSOLUTE_REPORT_DIRECTORY} ${ARCHIVE_REPORT_DIRECTORY}/${ROOT_ID}"
        fi

        cp -Rf ${ABSOLUTE_REPORT_DIRECTORY} ${ARCHIVE_REPORT_DIRECTORY}/${ROOT_ID} > /dev/null

        if (( DEBUG == "1" )); then
            echo "BEFORE KILL"
        fi

        sleep 5

        killAllThreads

        if (( DEBUG == "1" )); then
            echo "AFTER FIRST KILL, BEFORE EXIT 0"
        fi

        exit 0
    fi

    if [ "${WITH_RERUNS}" != "true" ]; then

        if (( DEBUG == "1" )); then
            echo "RUN WITHOUT RERUNS, AND EXIST THREADS WITH STATUS 1"
        fi

#       all threads completed (but may be have failed)
        if (( DEBUG == "1" )); then
            echo "!!!REPORTS"
            echo "CREATE ${ARCHIVE_REPORT_DIRECTORY}/${ROOT_ID}"
        fi

        mkdir "${ARCHIVE_REPORT_DIRECTORY}/${ROOT_ID}" > /dev/null

        if (( DEBUG == "1" )); then
            echo "CHMOD 0775 ${ARCHIVE_REPORT_DIRECTORY}/${ROOT_ID}"
        fi

        chmod 0755 ${ARCHIVE_REPORT_DIRECTORY}/${ROOT_ID} > /dev/null

        if (( DEBUG == "1" )); then
            echo "COPY REPORTS ${ABSOLUTE_REPORT_DIRECTORY} ${ARCHIVE_REPORT_DIRECTORY}/${ROOT_ID}"
        fi

        cp -Rf ${ABSOLUTE_REPORT_DIRECTORY} ${ARCHIVE_REPORT_DIRECTORY}/${ROOT_ID} > /dev/null

        killAllThreads

        if (( DEBUG == "1" )); then
            echo "AFTER KILL"
        fi

        printFailedState

        echo -e "\x1b[5;41;37m###########################################################\x1b[0m"
        echo -e "\x1b[5;41;37m:::BDD FAILED !!! \x1b[0m"
        echo -e "\x1b[5;41;37m###########################################################\x1b[0m"
        exit 1
    fi
fi

echo -e '\E[37;44m'"\033[1m====================================\033[0m"

# print all status, rerun if need
for index in $(seq 0 ${LAST_THREAD_INDEX})
do

debugThreadId=${THREAD_IDS[$index]}
debugThreadGroup=${THREAD_GROUPS[$index]}
debugSqliteStatus=$(sqlite3 -init <(echo ".timeout 3000") ${ABSOLUTE_REPORT_DIRECTORY}/test.db "SELECT STATUS FROM THREAD_STATUSES WHERE THREAD_ID ='${debugThreadId}' LIMIT 1")

if (( DEBUG == "1" )); then
  echo "STATUS from SQLITE3: ${debugSqliteStatus} from STATUSES: ${THREAD_STATUSES[$index]} ::: id: ${debugThreadId}"
fi

# check any thread is rerun count = 0 and status = 1
# force kill all and echo bdd failed
if (( ${THREAD_STATUSES[$index]} == "1" )); then

  if (( DEBUG == "1" )); then
    echo "STATUS 1: ${THREAD_STATUSES[$index]}"
  fi

  if [ "${WITH_RERUNS}" = "true" ]; then

    if (( "${THREAD_RERUNS[$index]}" >= "0" )); then
      # rerun exist
      if (( DEBUG == "1" )); then
        echo "RERUN EXIST : ${THREAD_RERUNS[$index]}"
      fi

      echo -e "\x1b[5;41;37m:THREAD FAILED !!! (${THREAD_IDS[$index]})\x1b[0m"
      echo -e "\x1b[5;41;37m:RERUN(${THREAD_RERUNS[$index]}) FAILED THREAD  $index  ${THREAD_GROUPS[$index]} (${THREAD_IDS[$index]})\x1b[0m"

      let THREAD_RERUNS[$index]=${THREAD_RERUNS[$index]}-1
      rerunFailedThreads ${index} ${THREAD_RERUNS[$index]}

    else
      # rerun empty
      if (( DEBUG == "1" )); then
        echo "RERUN EMPTY : ${THREAD_RERUNS[$index]}"
      fi

      echo -e '\E[37;44m'"\033[1m:RERUN IS EMPTY FOR $index  ${THREAD_GROUPS[$index]} (${THREAD_IDS[$index]})\x1b[0m"
      echo -e "\x1b[5;41;37m:THREAD FAILED !!! (${THREAD_IDS[$index]})\x1b[0m"

      mkdir ${ARCHIVE_REPORT_DIRECTORY}/${ROOT_ID}
      chmod 0755 ${ARCHIVE_REPORT_DIRECTORY}/${ROOT_ID}
      cp -Rf ${ABSOLUTE_REPORT_DIRECTORY} ${ARCHIVE_REPORT_DIRECTORY}/${ROOT_ID}

      killAllThreads
      printFailedState

      echo -e "\x1b[5;41;37m###########################################################\x1b[0m"
      echo -e "\x1b[5;41;37m:::BDD FAILED !!! \x1b[0m"
      echo -e "\x1b[5;41;37m###########################################################\x1b[0m"
      exit 1
    fi
  fi
fi


if (( ${THREAD_STATUSES[$index]} == "2" )); then

  if (( DEBUG == "1" )); then
    echo "STATUS 2: ${THREAD_STATUSES[$index]}"
  fi

  echo -e "\x1b[37;43m:THREAD  $index  ${THREAD_GROUPS[$index]} IN PROGRESS (${THREAD_IDS[$index]})... \x1b[0m"
fi

if (( ${THREAD_STATUSES[$index]} == "0" )); then

  if (( DEBUG == "1" )); then
      echo "STATUS 0: ${THREAD_STATUSES[$index]}"
  fi

    if [ "${THREAD_SHOW_STATUSES[$index]}" = "true" ]; then

      if (( DEBUG == "1" )); then
        echo "NEED SHOW: ${THREAD_SHOW_STATUSES[$index]}"
      fi

      echo -e "\x1b[5;42;37m:THREAD  $index  ${THREAD_GROUPS[$index]} BDD COMPLETED (${THREAD_IDS[$index]})\x1b[0m"
      sqlite3 -init <(echo ".timeout 3000") ${ABSOLUTE_REPORT_DIRECTORY}/test.db "UPDATE THREAD_STATUSES SET SHOW_STATUS= 'false' WHERE THREAD_ID= '${THREAD_IDS[$index]}';"

      THREAD_END_TIMES[$index]=$(date +"%T")
    else
      if (( DEBUG == "1" )); then
        echo "NEED HIDE: ${THREAD_SHOW_STATUSES[$index]}"
      fi
    fi
fi

sleep 2

done

echo -e '\E[37;44m'"\033[1m====================================\033[0m"

sleep 60

if (( DEBUG == "1" )); then
    echo "pause completed"
fi


done

