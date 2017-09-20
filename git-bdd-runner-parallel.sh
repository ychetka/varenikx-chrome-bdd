#!/bin/bash

#$1 - GIT data
#'{"repository":"aaa..","token":"bbb...","pullRequestId":"ccc...","branch":"ddd..."}'

#$2 - theards JSON
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

function killAllTheards {
  echo -e "\x1b[5;41;37m killAllTheards (one theard failed)                                                                                             \x1b[0m"
  docker kill $(docker ps -q)
}

#$1 index
function unshiftFromTheards {
  THEARD_IDS[$1]=
  THEARD_GROUPS[$1]=
  THEARD_DIRS[$1]=
  THEARD_LOGS[$1]=

  TMP_THEARD_IDS=( )
  TMP_THEARD_GROUPS=( )
  TMP_THEARD_DIRS=( )
  TMP_THEARD_LOGS=( )

  for index in "${!THEARD_IDS[@]}";
    do
      if [ -n "${THEARD_IDS[$index]}" ]; then
        TMP_THEARD_IDS=( "${TMP_THEARD_IDS[@]}" "${THEARD_IDS[$index]}")
        TMP_THEARD_GROUPS=( "${TMP_THEARD_GROUPS[@]}" "${THEARD_GROUPS[$index]}")
        TMP_THEARD_DIRS=( "${TMP_THEARD_DIRS[@]}" "${THEARD_DIRS[$index]}")
        TMP_THEARD_LOGS=( "${TMP_THEARD_LOGS[@]}" "${THEARD_LOGS[$index]}")
      fi
  done

  THEARD_IDS=( "${TMP_THEARD_IDS[@]}" )
  THEARD_GROUPS=( "${TMP_THEARD_GROUPS[@]}" )
  THEARD_DIRS=( "${TMP_THEARD_DIRS[@]}" )
  THEARD_LOGS=( "${TMP_THEARD_LOGS[@]}" )
}

cd $HOME

ROOTID=$(uuidgen)

mkdir $ROOTID
chmod 0777 $ROOTID

THEARDS_COUNT=$(echo $2 | jq -r '. | length')

echo -e '\E[37;44m'"\033[1mparallel-git-bdd-runner >> start parallel BDD > TIMEOUT 180 minutes\033[0m"
echo -e '\E[37;44m'"\033[1m $THEARDS_COUNT theards\033[0m"

let LAST_THEARD_INDEX=$THEARDS_COUNT-1

THEARD_IDS=( )
THEARD_GROUPS=( )
THEARD_DIRS=( )
THEARD_LOGS=( )

for i in $(seq 0 $LAST_THEARD_INDEX)
  do
    THEARD_ID=$(uuidgen)
    THEARD_DIR=$HOME/$ROOTID/$THEARD_ID
    THEARD_LOG=$HOME/$ROOTID/$i
    THEARD_GROUP=$(echo $2 | jq -r '.['$i']')

    THEARD_IDS=( "${THEARD_IDS[@]}" "$THEARD_ID")
    THEARD_DIRS=( "${THEARD_DIRS[@]}" "$THEARD_DIR")
    THEARD_LOGS=( "${THEARD_LOGS[@]}" "$THEARD_LOG")
    THEARD_GROUPS=( "${THEARD_GROUPS[@]}" "$THEARD_GROUP")

    #run bdd theard
    ~/git-bdd-runner.sh $1 $HOME/$ROOTID $THEARD_GROUP $THEARD_ID > $THEARD_LOG &
done

#$1 index
function getTheardResult {
      complited="${THEARD_DIRS[$1]}/0"
      failed="${THEARD_DIRS[$1]}/1"

      if [ -f "$complited" ]; then
         # theard ok
         echo "0"
      else
        if [ -f "$failed" ]; then
          # theard failed
          echo "1"
        else
          # theard in progress
          echo "2"
        fi
      fi
}

# 180 minutes
for i in $(seq 1 180)
  do

  #slep
  sleep 60

  #check bdd finish
  if ((${#THEARD_IDS[@]} == 0)); then
    #finish all
    echo -e "\x1b[5;42;37mALL THEARD END: BDD OK\x1b[0m"
    exit 0
  fi

  #get result for all container
  for index in "${!THEARD_DIRS[@]}";
    do
      if [ -n "${THEARD_DIRS[$index]}" ]; then
        #exist
        result=$(getTheardResult $index)

        if (($result == "0")); then
         # theard ok
         # remove ok theard dir
         echo -e "\x1b[5;42;37mTHEARD END:BDD OK\x1b[0m"
         cat ${THEARD_LOGS[$index]}

         unshiftFromTheards $index
         break
        else
          if (($result == "1")); then
            # theard failed
            killAllTheards
            cat ${THEARD_LOGS[$index]}
            exit 1
          else
            # theard in progress
            echo -e "\x1b[37;43m ${THEARD_GROUPS[$index]} in progress...\x1b[0m"
          fi
        fi
      fi
  done

  if (( $i == 179 )); then
    echo -e "\x1b[5;41;37mgit-bdd-runner >> Failed TIMEOUT\x1b[0m"
    exit 1
  fi

done

