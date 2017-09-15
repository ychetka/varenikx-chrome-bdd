#!/bin/bash

function initGit {
  echo -e "\x1b[5;42;37mGit mode\x1b[0m"

  export REPOSITORY=$(echo ${GIT} | jq -r '.repository')
  export AUTH_TOKEN=$(echo ${GIT} | jq -r '.token')
  export PULL_REQUEST_Id=$(echo ${GIT} | jq -r '.pullRequestId')
  export BRANCH=$(echo ${GIT} | jq -r '.branch')

  echo -e '\E[37;44m'"\033[1mREPOSITORY: $REPOSITORY\033[0m"
  echo -e '\E[37;44m'"\033[1mAUTH_TOKEN: $AUTH_TOKEN\033[0m"
  echo -e '\E[37;44m'"\033[1mPULL_REQUEST_Id: $PULL_REQUEST_Id\033[0m"
  echo -e '\E[37;44m'"\033[1mBRANCH: $BRANCH\033[0m"

  echo -e "\x1b[37;43mWaiting git...\x1b[0m"
  git init
  echo -e "\x1b[37;43mClone https://$AUTH_TOKEN@github.com/$REPOSITORY.git\x1b[0m"

  git clone https://$AUTH_TOKEN@github.com/$REPOSITORY.git ./project
  echo -e "\x1b[37;43mGet pr...\x1b[0m"

  cd $WORKDIR

  git fetch origin pull/$PULL_REQUEST_Id/head:$BRANCH
  git checkout $BRANCH
}

function initFiles {
  echo -e "\x1b[5;42;37mFile mode\x1b[0m"
  sudo -E -i -u root \
    cp -avr /project "/home/bdd/project" >  /dev/null
}

function setProjectAccess {
  sudo -E -i -u root \
    chmod -R 777 '/home/bdd'
  cd /home/bdd

  mkdir project

  export WORKDIR="/home/bdd/project"

  if [ -n "$GIT" ]; then
    initGit
  else
    initFiles
  fi

  sudo -E -i -u root \
    chmod -R 777 $WORKDIR
  sudo -E -i -u root \
    find $WORKDIR -type d -exec chmod 0777 {} ';'
}

setProjectAccess

export GEOMETRY="$SCREEN_WIDTH""x""$SCREEN_HEIGHT""x""$SCREEN_DEPTH"
export DISPLAY=:0

if [ -n "$GIT" ]; then
  export WEBPACKLOG=/$ID/webpack.log
else
  export WEBPACKLOG=$WORKDIR/webpack.log
fi


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

# $1 exit code
function shutdown () {
  if [ -n "$GIT" ]; then
    echo -e "$1" > /$ID/$1
  else
    echo -e "$1" > $WORKDIR/$1
  fi

  kill -s SIGTERM $NODE_PID
  wait $NODE_PID
}

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
        echo -e "\x1b[5;41;37mFailed yarn\x1b[0m"
        setState "init.failed"
        break
      fi
    fi

  sleep 5

  if (( $i == 99 )); then
    echo -e "\x1b[5;41;37mFailed TIMEOUT\x1b[0m"
    echo -e "\x1b[5;41;37mFailed yarn\x1b[0m"
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
        shutdown 1
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
          /bin/bash -c 'cd $WORKDIR && $RUN'

          isFailed=$(/bin/bash -c "$FAILEDPARSER");

          if [ -n "$RERUNCOUNT" ]; then

            if [ "$isFailed" = "true" ]; then
              for i in $(seq 1 $RERUNCOUNT)
                do
                  isFailed=$(/bin/bash -c "$FAILEDPARSER");

                  if [ "$isFailed" = "true" ]; then
                    echo -e "\x1b[5;41;37mBDD RERUN. Attempt number $i\x1b[0m"
                    echo -e '\E[37;44m'"\033[1mRUN: $RUN --rerun\033[0m"
                    /bin/bash -c 'cd $WORKDIR && $RUN --rerun'
                  else
                    break
                  fi
              done

              isFailed=$(/bin/bash -c "$FAILEDPARSER");
            fi
          fi

          #FIXME система статистики
          if [ "$isFailed" = "true" ]; then
            echo -e "\x1b[5;41;37mBDD: FAILED\x1b[0m"
            shutdown 1
            else
            echo -e '\E[37;44m'"\033[1mBDD: ENDED!\033[0m"
            shutdown 0
          fi
        fi

        break
      fi

      if (( $i == 99 )); then
        echo -e $TIMEOUTMESSAGE
        shutdown 1
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
    echo -e "\x1b[5;41;37mFailed 1\x1b[0m"
    shutdown 1
fi


wait $NODE_PID