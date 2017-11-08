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
  echo -e "\x1b[37;43m>>YARN-WORKER >> RUN YARN DEPLOY...\x1b[0m"
  cd $1

  yarn install >> $2 || error "\x1b[5;41;37m>>YARN-WORKER >> YARN INSTALL FAILED \x1b[0m"
  complited "\x1b[5;42;37m>>YARN-WORKER >> YARN INSTALL OK\x1b[0m"

  #yarn webpack --local >> $2 || error "\x1b[5;41;37m>>YARN-WORKER >> WEBPACK COMPILE FAILED \x1b[0m"
  #complited "\x1b[5;42;37m>>YARN-WORKER >> DEPLOY OK\x1b[0m"

  exit 0
}

export -f initYarn

initYarn $1 $2