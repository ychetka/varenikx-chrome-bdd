#!/bin/bash

ID=$(uuidgen)

mkdir $ID

function killContainer {
  containerId=$(docker ps -aqf "name=$ID")
  docker kill $containerId
}

cd $HOME




COMMAND="yarn run test:spec -- --workspace=fe1.corplan.ru --skipMenu --skipTags=blank,bug,modeller"

docker run --name "$ID" -e ID="$ID" -e GIT="$1" -e RERUNCOUNT="5" -e FAILEDPARSER="node ./bin/cucumber-failed-parser.js" -e RUN="$COMMAND" -v "$HOME/$ID/":"/$ID" varenikx/chrome-bdd:latest &

# 90 minutes
for i in $(seq 1 60)
  do
    #slep
    sleep 90

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

    if (( $i == 59 )); then
      killContainer
      sleep 10
      echo -e "\x1b[5;41;37mFailed TIMEOUT\x1b[0m"
      exit 1
    fi
done