#!/bin/bash

#$1 - GIT data
#'{"repository":"aaa..","token":"bbb...","pullRequestId":"ccc...","branch":"ddd..."}'

#$2 - theards JSON - support tags and groups
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

GIT=$1
FEATURES=$2
ROOTID=$(uuidgen)
THEARDS_COUNT=$(echo $FEATURES | jq -r '. | length')
let LAST_THEARD_INDEX=$THEARDS_COUNT-1
THEARD_IDS=( )
THEARD_GROUPS=( )
THEARD_DIRS=( )
THEARD_LOGS=( )
THEARD_STATES=( )
THEARD_HOSTS=( )
THEARD_PORTS=( )
THEARD_CPUS=( "0-1" "2-3" "4-5" "6-7" "8-9" "10-11" "11-12" "13-14" )
THEARD_RERUNS=( )

function killAllTheards {
  if [ -z "$1" ]; then
    echo -e "\x1b[5;41;37m>>>>>>>>>>STOP ALL THEARDS \x1b[0m"
  fi

  docker kill $(docker ps -q) &> /dev/null
}

#$1 container name
function killTheard {
  containerId=$(docker ps -aqf "name=$1")
  docker kill $containerId &> /dev/null
}

function random_free_tcp_port {
  local ports="${1:-1}" interim="${2:-2048}" spacing=32
  local free_ports=( )
  local taken_ports=( $( netstat -aln | egrep ^tcp | fgrep LISTEN |
                         awk '{print $4}' | egrep -o '[0-9]+$' |
                         sort -n | uniq ) )
  interim=$(( interim + (RANDOM % spacing) ))

  for taken in "${taken_ports[@]}" 65535
  do
    while [[ $interim -lt $taken && ${#free_ports[@]} -lt $ports ]]
    do
      free_ports+=( $interim )
      interim=$(( interim + spacing + (RANDOM % spacing) ))
    done
    interim=$(( interim > taken + spacing
                ? interim
                : taken + spacing + (RANDOM % spacing) ))
  done

  [[ ${#free_ports[@]} -ge $ports ]] || return 2

  echo "${free_ports[@]}"
}

#$1 index $2 state (0 | 1)
function changeTheardState {
  THEARD_STATES[$1]=$2
}

#$1 index
function getTheardResult {
  complited="${THEARD_DIRS[$1]}/0"
  failed="${THEARD_DIRS[$1]}/1"

  if [ -f "$complited" ]; then
    # theard ok
    echo 0
  else
    if [ -f "$failed" ]; then
      # theard failed
      echo 1
    else
      # theard in progress
      echo 2
    fi
  fi
}

#$1 print without log
function printAllState {
  for index in "${!THEARD_DIRS[@]}";
    do
      if (( "${THEARD_STATES[$index]}" == "1" )); then
        echo -e "\x1b[5;41;37m>>>>>>>>>>THEARD  $index  ${THEARD_GROUPS[$index]}  FAILED \x1b[0m"
      fi

      if (( "${THEARD_STATES[$index]}" == "0" )); then
        echo -e "\x1b[5;42;37m>>>>>>>>>>THEARD  $index  ${THEARD_GROUPS[$index]}  OK \x1b[0m"
      fi

      if (( "${THEARD_STATES[$index]}" == "2" )); then
        echo -e "\x1b[37;43m>>>>>>>>>>THEARD  $index  ${THEARD_GROUPS[$index]}  IN PROGRESS \x1b[0m"
      fi
  done

  if [ -z "$1" ]; then
    for index in "${!THEARD_DIRS[@]}";
      do
        if (( "${THEARD_STATES[$index]}" == "1" )); then
          echo -e "\x1b[5;41;37m#####################################################\x1b[0m"
          echo -e "\x1b[5;41;37m>>>>>>>>>>THEARD FAILED $index  ${THEARD_GROUPS[$index]}   \x1b[0m"
          echo -e "\x1b[5;41;37m#####################################################\x1b[0m"
        fi

      cat "${THEARD_LOGS[$index]}"
    done
  fi
}

function printFailedState {
  for index in "${!THEARD_DIRS[@]}";
    do
      if (( "${THEARD_STATES[$index]}" == "1" )); then
        echo -e "\x1b[5;41;37m#####################################################\x1b[0m"
        echo -e "\x1b[5;41;37m>>>>>>>>>>THEARD FAILED $index  ${THEARD_GROUPS[$index]}   \x1b[0m"
        echo -e "\x1b[5;41;37m#####################################################\x1b[0m"
      fi

      cat "${THEARD_LOGS[$index]}"
  done
}

#$1 thead index
function rerunFailedTheards {
  THEARD_ID=$(uuidgen)
  THEARD_DIR=$HOME/$ROOTID/$THEARD_ID
  THEARD_STATE=2
  THEARD_HOST="127.0.0.1"
  THEARD_PORT=$(random_free_tcp_port)

  mkdir $THEARD_DIR

  if [ -f "${THEARD_DIRS[$1]}/@rerun.txt" ]; then
    echo -e '\E[37;44m'"\033[1m>>>>>>>>>>USE EXTERNAL RERUN ${THEARD_DIRS[$1]}/@rerun.txt FOR ${THEARD_GROUPS[$1]} \033[0m"
    cp "${THEARD_DIRS[$1]}/@rerun.txt" "$THEARD_DIR/@rerun.txt"
    rm -rf "${THEARD_DIRS[$1]}/@rerun.txt"
  fi

  #REMOVE OLD THEARD DIRECTORY
  rm -rf "${THEARD_DIRS[$1]}"

  PPP_STATE=$(ip link show | grep ppp0)

  if [ -n "$PPP_STATE" ]; then
    THEARD_HOST="10.0.0.1"
  fi

  THEARD_IDS[$1]=$THEARD_ID
  THEARD_DIRS[$1]=$THEARD_DIR
  THEARD_STATES[$1]=$THEARD_STATE
  THEARD_HOSTS[$1]=$THEARD_HOST
  THEARD_PORTS[$1]=$THEARD_PORT

  ~/git-bdd-runner.sh $GIT $HOME/$ROOTID ${THEARD_GROUPS[$1]} ${THEARD_IDS[$1]} ${THEARD_HOSTS[$1]} ${THEARD_PORTS[$1]} ${THEARD_CPUS[$1]}> ${THEARD_LOGS[$1]} &
  sleep 10
}


############## START THEARDS
cd $HOME

mkdir $ROOTID
chmod 0777 $ROOTID

echo -e '\E[37;44m'"\033[1m>>>>>>>>>> <br> BUILD ID  $ROOTID <br> \033[0m"
echo -e '\E[37;44m'"\033[1m>>>>>>>>>>$THEARDS_COUNT THEARDS WITH TIMEOUT 180 minutes \033[0m"


for i in $(seq 0 $LAST_THEARD_INDEX)
  do
    THEARD_ID=$(uuidgen)
    THEARD_DIR=$HOME/$ROOTID/$THEARD_ID
    THEARD_LOG=$HOME/$ROOTID/$i
    THEARD_GROUP=$(echo $FEATURES | jq -r '.['$i']')
    THEARD_STATE=2
    THEARD_HOST="127.0.0.1"
    THEARD_PORT=$(random_free_tcp_port)
    THEARD_RERUN=5

    PPP_STATE=$(ip link show | grep ppp0)
    if [ -n "$PPP_STATE" ]; then
      THEARD_HOST="10.0.0.1"
    fi

    THEARD_IDS=( "${THEARD_IDS[@]}" "$THEARD_ID" )
    THEARD_DIRS=( "${THEARD_DIRS[@]}" "$THEARD_DIR" )
    THEARD_LOGS=( "${THEARD_LOGS[@]}" "$THEARD_LOG" )
    THEARD_GROUPS=( "${THEARD_GROUPS[@]}" "$THEARD_GROUP" )
    THEARD_STATES=( "${THEARD_STATES[@]}" "$THEARD_STATE" )
    THEARD_HOSTS=( "${THEARD_HOSTS[@]}" "$THEARD_HOST" )
    THEARD_PORTS=( "${THEARD_PORTS[@]}" "$THEARD_PORT" )

    THEARD_RERUNS=( "${THEARD_RERUNS[@]}" "$THEARD_RERUN" )


    #run bdd theard
    echo -e '\E[37;44m'"\033[1m>>>>>>>>>>RUN THEARD $THEARD_GROUP $THEARD_ID on CPUs ${THEARD_CPUS[$i]}\033[0m"
    ~/git-bdd-runner.sh $GIT $HOME/$ROOTID $THEARD_GROUP $THEARD_ID $THEARD_HOST $THEARD_PORT ${THEARD_CPUS[$i]} > $THEARD_LOG &
    sleep 10
done


############## WATCH THEARDS
# 180 minutes
for i in $(seq 1 180)
  do

  #slep
  sleep 60

  #check bdd finish
  #ckeck failed and rerun theards
  if [ -n "$(echo ${THEARD_STATES[*]} | grep '1')" ]; then
    #rerun theard
    for index in "${!THEARD_STATES[@]}";
      do
        if (( "${THEARD_STATES[$index]}" == "1" )); then

           if (( "${THEARD_RERUNS[$index]}" >= "0" )); then
             echo -e '\E[37;44m'"\033[1m###########################################################\033[0m"
             echo -e '\E[37;44m'"\033[1m>>>>>>>>>>RERUN(${THEARD_RERUNS[$index]}) FAILED THEARD $index >> ${THEARD_GROUPS[$index]} \033[0m"
             echo -e '\E[37;44m'"\033[1m###########################################################\033[0m"

             let THEARD_RERUNS[$index]=${THEARD_RERUNS[$index]}-1
             rerunFailedTheards $index

           else
             echo -e "\x1b[5;41;37m###########################################################\x1b[0m"
             echo -e "\x1b[5;41;37m>>>>>>>>>>ATTEMPT THEARD RERUNS IN ${THEARD_GROUPS[$index]} IS EMPTY! \x1b[0m"
             echo -e "\x1b[5;41;37m###########################################################\x1b[0m"

             killAllTheards
             printFailedState

             echo -e "\x1b[5;41;37m###########################################################\x1b[0m"
             echo -e "\x1b[5;41;37m>>>>>>>>>>BDD FAILED !!! \x1b[0m"
             echo -e "\x1b[5;41;37m###########################################################\x1b[0m"

             exit 1
           fi

        fi
    done
  fi

  #exist in progress
  if [ -z "$(echo ${THEARD_STATES[*]} | grep '2')" ]; then
      #all theards ok
      #FIXME print all state
      printAllState "withoutLogs"
      echo -e "\x1b[5;42;37m>>>>>>>>>>ALL THEARDS END  BDD OK\x1b[0m"
      killAllTheards true
      exit 0
  fi

  #get result for all container
  for index in "${!THEARD_DIRS[@]}";
    do
      if (( "${THEARD_STATES[$index]}" == "2" )); then
        #exist
        result=$(getTheardResult $index)

        if (( "$result" == "0" )); then
         # theard ok
         echo -e "\x1b[5;42;37m>>>>>>>>>>THEARD  $index  ${THEARD_GROUPS[$index]} BDD OK\x1b[0m"
         changeTheardState $index 0
         killTheard ${THEARD_IDS[$index]}
        else
          if (( "$result" == "1" )); then
            # theard failed
            echo -e "\x1b[5;41;37m>>>>>>>>>>THEARD  $index  ${THEARD_GROUPS[$index]} BDD FAILED \x1b[0m"
            changeTheardState $index 1
            killTheard ${THEARD_IDS[$index]}
          else
            # theard in progress
            echo -e "\x1b[37;43m>>>>>>>>>>THEARD  $index  ${THEARD_GROUPS[$index]} in progress... \x1b[0m"
          fi
        fi
      fi
  done

  if (( "$i" == "178" )); then
    echo -e "\x1b[5;41;37m###########################################################\x1b[0m"
    echo -e "\x1b[5;41;37m>>>>>>>>>>BDD FAILED TIMEOUT\x1b[0m"
    echo -e "\x1b[5;41;37m###########################################################\x1b[0m"

    ##print all state
    printFailedState
    killAllTheards
    exit 1
  fi

done

