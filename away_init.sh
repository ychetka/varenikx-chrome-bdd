#!/bin/bash

for i in $(seq 1 100)
do

echo -e "\x1b[37;43mWaiting init...\x1b[0m"
sleep 3


if [ -f "$WORKDIR/init.failed" ]; then
  echo -e $ERRORMESSAGE
  catLog
  exit 1
fi

if [ -f "$WORKDIR/init.started" ]; then

  echo -e "\x1b[5;42;37mWORKDIR: $WORKDIR\x1b[0m"
  echo -e "\x1b[5;42;37mXDPY: OK\x1b[0m"
  echo -e "\x1b[5;42;37mYARN: OK\x1b[0m"
  echo -e "\x1b[5;42;37mWEBPACK: OK\x1b[0m"

  echo -e "\x1b[37;43mSystem\x1b[0m"
  echo $(lsb_release -a)

  echo -e $RESOLUTION
  echo -e "\x1b[5;42;37mYou must connect with VNC client\x1b[0m"
  echo -e "\x1b[5;42;37mNetwork information\x1b[0m"
  eval "/sbin/ifconfig"

  echo -e "\x1b[37;43mnode version\x1b[0m $(node -v)"
  echo -e "\x1b[37;43mnpm version\x1b[0m $(npm -v)"
  echo -e "\x1b[37;43mxvfb\x1b[0m $(apt-cache show xvfb | grep -i version)"
  echo -e "\x1b[37;43mgoogle-chrome-stable\x1b[0m $(apt-cache show google-chrome-stable | grep -i version)"
  echo -e "\x1b[37;43myarn version\x1b[0m $(yarn --version)"
  echo -e "$(java -version)"

  sleep 5

  if [ -n "$RUN" ]; then
    echo -e "\x1b[5;42;37mRUN: $RUN\x1b[0m"
    eval $RUN
  fi

  break
fi

if [ i = 99 ]; then
  echo -e $TIMEOUTMESSAGE
  catLog
  break
  exit 1
fi

done
