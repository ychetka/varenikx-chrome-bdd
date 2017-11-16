#!/bin/bash

# $1 - git data
# $2 - output directory

function error {
  echo -e "\x1b[5;41;37m>>GIT-WORKER >> FAILED \x1b[0m"
  exit 1
}

function complited {
  echo -e "\x1b[5;42;37m>>GIT-WORKER >> GET FILES OK\x1b[0m"
}

function cloneRepository {
  export REPOSITORY=$(echo ${1} | jq -r '.repository')
  export AUTH_TOKEN=$(echo ${1} | jq -r '.token')
  export PULL_REQUEST_ID=$(echo ${1} | jq -r '.pullRequestId')
  export BRANCH=$(echo ${1} | jq -r '.branch')

  rm -rf $2
  mkdir -p $2

  echo -e "\x1b[37;43m>>GIT-WORKER >> WAITING GIT...\x1b[0m"

  #git init || error
  echo -e "\x1b[37;43m>>GIT-WORKER >> CLONE https://$AUTH_TOKEN@github.com/$REPOSITORY.git\x1b[0m"

  git clone https://$AUTH_TOKEN@github.com/$REPOSITORY.git "$2" || error

  echo -e "\x1b[37;43m>>GIT-WORKER >> LOAD PULL REQUEST...\x1b[0m"
  cd $2
  git fetch origin pull/$PULL_REQUEST_ID/head:$BRANCH || error
  git checkout $BRANCH || error
}

#$1 gitdata
#$2 output
function initGitData {
  rm -rf $2
  mkdir -p $2

  echo -e "\x1b[5;42;37m>>GIT-WORKER >> GIT MODE \x1b[0m"

  export REPOSITORY=$(echo ${1} | jq -r '.repository')
  export AUTH_TOKEN=$(echo ${1} | jq -r '.token')
  export PULL_REQUEST_ID=$(echo ${1} | jq -r '.pullRequestId')
  export BRANCH=$(echo ${1} | jq -r '.branch')

  echo -e '\E[37;44m'"\033[1m>>GIT-WORKER >> REPOSITORY: $REPOSITORY\033[0m"
  echo -e '\E[37;44m'"\033[1m>>GIT-WORKER >> AUTH_TOKEN: $AUTH_TOKEN\033[0m"
  echo -e '\E[37;44m'"\033[1m>>GIT-WORKER >> PULL_REQUEST_ID: $PULL_REQUEST_ID\033[0m"
  echo -e '\E[37;44m'"\033[1m>>GIT-WORKER >> BRANCH: $BRANCH\033[0m"

  echo -e "\x1b[37;43m>>GIT-WORKER >> WAITING GIT...\x1b[0m"
  git init || error

  echo -e "\x1b[37;43m>>GIT-WORKER >> CLONE https://$AUTH_TOKEN@github.com/$REPOSITORY.git\x1b[0m"
  git clone https://$AUTH_TOKEN@github.com/$REPOSITORY.git "$2" || error
  echo -e "\x1b[37;43m>>GIT-WORKER >> LOAD PULL REQUEST...\x1b[0m"

  cd $2

  git fetch origin pull/$PULL_REQUEST_Id/head:$BRANCH
  git checkout $BRANCH

  complited
}

export -f initGitData

initGitData $1 $2