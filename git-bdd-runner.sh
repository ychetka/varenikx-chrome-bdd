#!/bin/bash

##$1 git data
##$2 home dir
##$3 features group - support tag and group
##$4 id
##$5 host for mapping
##$6 port for mapping
##$7 workspace

function killContainer {
  containerId=$(docker ps -aqf "name=$ID")
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

ID=
AHOME=
HOST_IP=
FREEPORT=
WORKSPACE=

if [ -n "$7" ]; then
  WORKSPACE=$7
else
  WORKSPACE="bdd.corplan.ru"
fi

if [ -n "$6" ]; then
  FREEPORT=$6
else
  FREEPORT=$(random_free_tcp_port)
fi

if [ -n "$5" ]; then
  HOST_IP=$5
else
  PPP_STATE=$(ip link show | grep ppp0)
  if [ -n "$PPP_STATE" ]; then
    HOST_IP="10.0.0.10"
  else
    HOST_IP="127.0.0.1"
  fi
fi

if [ -n "$4" ]; then
   ID=$4
else
   ID=$(uuidgen)
fi

if [ -n "$2" ]; then
   AHOME=$2
else
   AHOME=$HOME
fi

cd $AHOME

if [ ! -d "$ID" ]; then
  mkdir $ID
fi

chmod 0777 $ID



if [ -f "$AHOME/$ID/@rerun.txt" ]; then
   echo -e '\E[37;44m'"\033[1m>>>THEARD >> RERUN MODE >> TIMEOUT 180 minutes\033[0m"
else
   echo -e '\E[37;44m'"\033[1m>>>THEARD >> RUN MODE >> TIMEOUT 180 minutes\033[0m"
fi

if [ -n "$3" ]; then
  SETTING=$(echo "$3"| cut -d':' -f 1)
  VALUE=$(echo "$3"| cut -d':' -f 2)

  #$SETTING=$VALUE example: filter=foo, tags=bar, skipMenu=baz

  COMMAND="yarn run test:spec -- --$SETTING=$VALUE --workspace=$WORKSPACE --skipMenu"
else
  COMMAND="yarn run test:spec -- --workspace=$WORKSPACE --skipMenu --skipTags=blank,bug,modeller"
fi

docker run --name "$ID" -p $HOST_IP:$FREEPORT:5900 -e HOST_IP="$HOST_IP" -e VNCPORT="$FREEPORT" -e ID="$ID" -e GIT="$1" -e FAILEDPARSER="node ./bin/cucumber-failed-parser.js" -e RUN="$COMMAND" -v "$AHOME/$ID/":"/$ID" varenikx/chrome-bdd:latest &

# 180 minutes
for i in $(seq 1 180)
  do
    #slep
    sleep 60

    if [ -f "$AHOME/$ID/1" ]; then
      # failed
      # for jenkins failed
      killContainer
      sleep 10
      exit 1
    fi

    if [ -f "$AHOME/$ID/0" ]; then
      # ok
      killContainer
      sleep 10
      exit 0
    fi

    if (( $i == 175 )); then
      killContainer
      sleep 10
      echo -e "\x1b[5;41;37m>>>THEARD FAILED TIMEOUT \x1b[0m"
      exit 1
    fi
done