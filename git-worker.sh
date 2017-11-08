#!/bin/bash

# $1 - git data
# $2 - output directory

function error {
  echo -e "\x1b[5;41;37m>>GIR-WORKER >> FAILED \x1b[0m"
  exit 1
}

function complited {
  echo -e "\x1b[5;42;37m>>GIR-WORKER >> GET FILES OK\x1b[0m"
  exit 0
}

function initGitData {
  echo -e "\x1b[5;42;37m>>GIR-WORKER >> GIT MODE \x1b[0m"

  rm -rf $2
  mkdir -p $2

  export REPOSITORY=$(echo ${1} | jq -r '.repository')
  export AUTH_TOKEN=$(echo ${1} | jq -r '.token')
  export PULL_REQUEST_ID=$(echo ${1} | jq -r '.pullRequestId')
  export BRANCH=$(echo ${1} | jq -r '.branch')

  echo -e '\E[37;44m'"\033[1m>>GIR-WORKER >> REPOSITORY: $REPOSITORY\033[0m"
  echo -e '\E[37;44m'"\033[1m>>GIR-WORKER >> AUTH_TOKEN: $AUTH_TOKEN\033[0m"
  echo -e '\E[37;44m'"\033[1m>>GIR-WORKER >> PULL_REQUEST_ID: $PULL_REQUEST_ID\033[0m"
  echo -e '\E[37;44m'"\033[1m>>GIR-WORKER >> BRANCH: $BRANCH\033[0m"

  echo -e "\x1b[37;43m>>GIR-WORKER >> WAITING GIT...\x1b[0m"
  git init || error
  echo -e "\x1b[37;43m>>GIR-WORKER >> CLONE https://$AUTH_TOKEN@github.com/$REPOSITORY.git\x1b[0m"

  git clone https://$AUTH_TOKEN@github.com/$REPOSITORY.git "$2" || error
  echo -e "\x1b[37;43m>>GIR-WORKER >> LOAD PULL REQUEST...\x1b[0m"

  cd $2

  git fetch origin pull/$PULL_REQUEST_ID/head:$BRANCH || error
  git checkout $BRANCH || error

  complited
}

export -f initGitData

initGitData $1 $2