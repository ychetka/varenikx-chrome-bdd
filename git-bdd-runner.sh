#!/bin/bash

ID=$(uuidgen)

mkdir $ID

function killContainer {
  containerId=$(docker ps -aqf "name=$ID")
  docker kill $containerId
}

cd $HOME

echo -e '\E[37;44m'"\033[1mgit-bdd-runner >> start BDD > TIMEOUT 180 minutes\033[0m"

COMMAND="yarn run test:spec -- --workspace=bdd.corplan.ru --modelId=3c5008d019203fcdfcb9226435580787 --skipMenu --skipTags=blank,bug,modeller"

docker run --name "$ID" -e ID="$ID" -e GIT="$1" -e RERUNCOUNT="5" -e FAILEDPARSER="node ./bin/cucumber-failed-parser.js" -e RUN="$COMMAND" -v "$HOME/$ID/":"/$ID" varenikx/chrome-bdd:latest &

# 180 minutes
for i in $(seq 1 180)
  do
    #slep
    sleep 60

    if [ -f "$HOME/$ID/1" ]; then
      # failed
      # for jenkins failed
      killContainer
      sleep 10
      exit 1
    fi

    if [ -f "$HOME/$ID/0" ]; then
      # ok
      killContainer
      sleep 10
      exit 0
    fi

    if (( $i == 179 )); then
      killContainer
      sleep 10
      echo -e "\x1b[5;41;37mgit-bdd-runner >> Failed TIMEOUT\x1b[0m"
      exit 1
    fi
done