#!/bin/bash

##$1 directory with project
##$2 home dir
##$3 features group - support tags and filter
##$4 id
##$5 workspace

#
#./file-bdd-runner.sh run with directory:/home/bdd/src AHOME:/home/bdd/96cfde18-2872-451c-86db-4809101cf0a5 group:filter:features/_service/test-trash-typing.feature ID:52cf7563-df97-43a0-aeb6-b18dca455522 WORKSPACE:bdd1.optimacros.com

#UNCOMMENT FOR VIEW DETAILS
#echo -e "\x1b[5;42;37m>>> /file-bdd-runner.sh run with directory:$1 AHOME:$2 group:$3 ID:$4 WORKSPACE:$5\x1b[0m"


ID=
AHOME=
WORKSPACE=

function killContainer {
  containerId=$(docker ps -aqf "name=${ID}")
  docker kill ${containerId} &> /dev/null
}

if [ -n "${5}" ]; then
  WORKSPACE=$5
else
  WORKSPACE="demo.optimacros.com"
fi

if [ -n "${4}" ]; then
   ID=$4
else
   ID=$(uuidgen)
fi

if [ -n "${2}" ]; then
   AHOME="${2}"
else
   AHOME="${HOME}"
fi

cd $AHOME

if [ ! -d "${ID}" ]; then
  mkdir "${ID}"
fi

chmod 0777 "${ID}"

if [ -n "${3}" ]; then
  SETTING=$(echo "${3}"| cut -d':' -f 1)
  VALUE=$(echo "${3}"| cut -d':' -f 2)

  COMMAND="yarn run test:bdd --dockerMode=true --useLocalProxy=true --${SETTING} \"${VALUE}\" --apiHost=\"${WORKSPACE}\""
else
  COMMAND="yarn run test:bdd --dockerMode=true --useLocalProxy=true --apiHost=\"${WORKSPACE}\""
fi

#UNCOMENT FOR VIEW DETAILS
#echo -e '\E[37;44m'"\033[1m>>> YARN COMMAND ${COMMAND} \033[0m"
DOCKER_COMMAND="docker -D run -t --rm --name \"${ID}\" -e ID=\"${ID}\" -e FAILEDPARSER=\"node ./bin/cucumber-failed-parser.js\" -e RUN=\"${COMMAND}\" -v \"${AHOME}/${ID}/\":\"/${ID}\" -v \"${1}/\":\"/project\" varenikx/chrome-bdd:latest"
echo -e '\E[37;44m'"\033[1m>>> DOCKER CONTAINER RUN AT COMMAND: ${DOCKER_COMMAND} \033[0m"

docker -D run -t --rm --name "${ID}" -e ID="${ID}" -e FAILEDPARSER="node ./bin/cucumber-failed-parser.js" -e RUN="${COMMAND}" -v "${AHOME}/${ID}/":"/${ID}" -v "${1}/":"/project" varenikx/chrome-bdd:latest &

# 60 minutes
for i in $(seq 1 60)
  do
    #slep
    sleep 60

    if [ -f "${AHOME}/${ID}/1" ]; then
      # failed
      # for jenkins failed
      killContainer
      sleep 10
      exit 1
    fi

    if [ -f "${AHOME}/${ID}/0" ]; then
      # ok
      killContainer
      sleep 10
      exit 0
    fi

    if (( $i == 59 )); then
      killContainer
      sleep 10
      echo -e "\x1b[5;41;37m>>>THREAD FAILED TIMEOUT \x1b[0m"
      exit 1
    fi
done