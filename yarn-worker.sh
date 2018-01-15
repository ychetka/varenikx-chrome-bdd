#!/bin/bash

# $1 - input directory
# $2 - log file

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

  source ~/.nvm/nvm.sh
  nvm use "v6.11.3" &> /dev/null
  nvm alias default "v6.11.3" &> /dev/null

  echo -e '\E[37;44m'"\033[1m>>YARN-WORKER >> node VERSION $(node --version)\033[0m"
  echo -e '\E[37;44m'"\033[1m>>YARN-WORKER >> npm VERSION $(npm -v)\033[0m"

  npm install yarn -g &> /dev/null

  echo -e '\E[37;44m'"\033[1m>>YARN-WORKER >> YARN VERSION $(yarn --version)\033[0m"

  echo -e "\x1b[37;43m>>YARN-WORKER >> RUN YARN INSTALL...\x1b[0m"

  yarn install &> ./webpack.log  || error "\x1b[5;41;37m>>YARN-WORKER >> YARN INSTALL FAILED \x1b[0m"
  complited "\x1b[5;42;37m>>YARN-WORKER >> YARN INSTALL OK\x1b[0m"

  echo -e "\x1b[37;43m>>YARN-WORKER >> RUN WEBPACK COMPILE...\x1b[0m"
  yarn webpack --local --hot &> ./webpack.log

  WEBPACK=$(cat "./webpack.log" | grep 'ERROR in')

  if [ -n "$WEBPACK" ]; then
    #error
    error "\x1b[5;41;37m>>YARN-WORKER >> WEBPACK COMPILE FAILED \x1b[0m"
  else
    complited "\x1b[5;42;37m>>YARN-WORKER >> WEBPACK COMPILE OK\x1b[0m"
  fi

}

export -f initYarn

initYarn $1 $2