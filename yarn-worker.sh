#!/bin/bash

# $1 - input directory
# $2 - log file

PROJECT_NODE_VERSION="v8.11.2"

function error {
  echo -e $1
  exit 1
}

function complited {
  echo -e $1
}

function initYarn {
# install node modules, run webpack compile
  cd $1

  source ~/.nvm/nvm.sh &> /dev/null
  nvm install ${PROJECT_NODE_VERSION} &> /dev/null
  nvm use ${PROJECT_NODE_VERSION} &> /dev/null
  nvm alias default ${PROJECT_NODE_VERSION} &> /dev/null
  npm install yarn -g &> /dev/null

  echo -e '\E[37;44m'"\033[1m>>YARN-WORKER >> NODE VERSION $(node --version)\033[0m"
  echo -e '\E[37;44m'"\033[1m>>YARN-WORKER >> NPM VERSION $(npm -v)\033[0m"
  echo -e '\E[37;44m'"\033[1m>>YARN-WORKER >> YARN VERSION $(yarn --version)\033[0m"

  echo -e "\x1b[37;43m>>YARN-WORKER >> RUN YARN INSTALL...\x1b[0m"

  yarn install &> ./webpack.log  || error "\x1b[5;41;37m>>YARN-WORKER >> YARN INSTALL FAILED \x1b[0m"
  complited "\x1b[5;42;37m>>YARN-WORKER >> YARN INSTALL OK\x1b[0m"

  echo -e "\x1b[37;43m>>YARN-WORKER >> RUN WEBPACK COMPILE...\x1b[0m"
  yarn webpack --local --useWs &> ./webpack.log

  WEBPACK=$(cat "./webpack.log" | grep 'ERROR in')

  if [ -n "$WEBPACK" ]; then
    # error
    error "\x1b[5;41;37m>>YARN-WORKER >> WEBPACK COMPILE FAILED \x1b[0m"
  else
    # init server
    complited "\x1b[5;42;37m>>YARN-WORKER >> WEBPACK COMPILE OK\x1b[0m"
  fi

}

export -f initYarn

initYarn $1 $2