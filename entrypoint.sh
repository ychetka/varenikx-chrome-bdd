#!/bin/bash

function setProjectAccess {
  sudo -E -i -u root \
    cp -avr /project "/home/bdd/project" >  /dev/null

  export WORKDIR="/home/bdd/project"

  sudo -E -i -u root \
    chmod 777 $WORKDIR
  sudo -E -i -u root \
    chmod -R 777 $WORKDIR
  sudo -E -i -u root \
    find $WORKDIR -type d -exec chmod 0777 {} ';'
}

setProjectAccess

export GEOMETRY="$SCREEN_WIDTH""x""$SCREEN_HEIGHT""x""$SCREEN_DEPTH"
export DISPLAY=:0
export X11VNCLOG=$WORKDIR/x11vnc.log
export FLUXBOXLOG=$WORKDIR/fluxbox.log
export XVFBLOG=$WORKDIR/xvfb.log
export WEBPACKLOG=$WORKDIR/webpack.log

#red message
export ERRORMESSAGE="\x1b[5;41;37mFatal Error\x1b[0m"
export TIMEOUTMESSAGE="\x1b[5;41;37mFatal Error! Timeout!\x1b[0m"

#clear
if [ -f "$WORKDIR/init.failed" ]; then
  rm $WORKDIR/init.failed
fi
if [ -f "$WORKDIR/init.started" ]; then
  rm $WORKDIR/init.started
fi
if [ -f "$WEBPACKLOG" ]; then
  rm "$WEBPACKLOG"
fi

# $1 filename
function setState () {
  echo -e "$1" > $WORKDIR/$1
}
export -f setState

function shutdown {
  kill -s SIGTERM $NODE_PID
  wait $NODE_PID
}

# $1 filename
function catLog () {
  #orange
  echo -en "\033[37;1;41m webpack.log \033[0m"
  cat $WEBPACKLOG
}
export -f catLog

function initXvfb {

  Xvfb $DISPLAY -screen 0 $GEOMETRY &
  NODE_PID=$!

  for i in $(seq 1 10)
    do
      xdpyinfo -display $DISPLAY >/dev/null 2>&1
        if [ $? -eq 0 ]; then
          echo -e "\x1b[5;42;37m x-virtual frame buffer started\x1b[0m"
          break
        fi
      echo -e "\x1b[37;43mWaiting xvfb...\x1b[0m"
      sleep 0.5
  done

  fluxbox -display $DISPLAY &
  x11vnc -display $DISPLAY -bg -nopw -xkb -usepw -shared -repeat -loop -forever &
}

function info {
  echo -e "\x1b[37;43mSystem\x1b[0m"
  echo $(lsb_release -a)
  echo -e "\x1b[37;43mnode version\x1b[0m $(node -v)"
  echo -e "\x1b[37;43mnpm version\x1b[0m $(npm -v)"
  echo -e "\x1b[37;43myarn version\x1b[0m $(yarn --version)"
  echo -e "$(java -version)"
}



function _yarnWatcher {
# Wait webpack
for i in $(seq 1 100)
do
  WEBPACK=$(tail -1 $WEBPACKLOG | grep 'Compiled successfully')
    if [ -n "$WEBPACK" ]; then
      ## this finished away_init
      setState "init.started"
      break
    else
      WEBPACK=$(tail -1 $WEBPACKLOG | grep 'Failed')
      if [ -n "$WEBPACK" ]; then
        echo -e "\x1b[5;41;37mFailed\x1b[0m"
        setState "init.failed"
        break
      fi
    fi

  sleep 5
  if [ i = 99 ]; then
    echo -e "\x1b[5;41;37mFailed TIMEOUT\x1b[0m"
    echo -e "\x1b[5;41;37mFailed 1\x1b[0m"
    setState "init.failed"
    break
  fi
done
}

function initYarn {
# Install node_modules, run webpack compile, run yaxy proxy
  echo WORKDIR - $WORKDIR
  cd $WORKDIR
  yarn install
  node server.js --progress --local > $WEBPACKLOG &
  _yarnWatcher &
}

function webpackInitWatcher {
  for i in $(seq 1 100)
    do
      echo -e "\x1b[37;43mWaiting init webpack...\x1b[0m"
      sleep 5

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
        echo -e "\x1b[5;42;37mgoogle-chrome-stable: $(apt-cache show google-chrome-stable | grep -i version)\x1b[0m"

        echo -e '\E[37;44m'"\033[1mGEOMETRY: $GEOMETRY\033[0m"
        echo -e "\x1b[5;42;37mYou must connect with VNC client\x1b[0m"
        echo -e "\x1b[5;42;37mNetwork information\x1b[0m"
        echo -e "\x1b[5;42;37mip route: $(ip route show)\x1b[0m"
        eval "/sbin/ifconfig"

        sleep 10

        if [ -n "$RUN" ]; then
          echo -e '\E[37;44m'"\033[1mRUN: $RUN\033[0m"
          eval 'cd $WORKDIR && $RUN'
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
}

#start Xvfb
initXvfb

# Set access
if [ -f "$WORKDIR/package.json" ]; then
  info
  initYarn
  webpackInitWatcher
else
  setState 'init.failed'
  exit 1
fi


wait $NODE_PID