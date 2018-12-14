#!/bin/bash

function initGit {
  echo -e "\x1b[5;42;37m>>ENTRYPOINT >> GIT MODE \x1b[0m"

  export REPOSITORY=$(echo ${GIT} | jq -r '.repository')
  export AUTH_TOKEN=$(echo ${GIT} | jq -r '.token')
  export PULL_REQUEST_Id=$(echo ${GIT} | jq -r '.pullRequestId')
  export BRANCH=$(echo ${GIT} | jq -r '.branch')

  echo -e '\E[37;44m'"\033[1m>>ENTRYPOINT >> REPOSITORY: $REPOSITORY\033[0m"
  echo -e '\E[37;44m'"\033[1m>>ENTRYPOINT >> AUTH_TOKEN: $AUTH_TOKEN\033[0m"
  echo -e '\E[37;44m'"\033[1m>>ENTRYPOINT >> PULL_REQUEST_Id: $PULL_REQUEST_Id\033[0m"
  echo -e '\E[37;44m'"\033[1m>>ENTRYPOINT >> BRANCH: $BRANCH\033[0m"

  echo -e "\x1b[37;43m>>ENTRYPOINT >> WAITING GIT...\x1b[0m"
  git init
  echo -e "\x1b[37;43m>>ENTRYPOINT >> CLONE https://$AUTH_TOKEN@github.com/$REPOSITORY.git\x1b[0m"

  git clone https://$AUTH_TOKEN@github.com/$REPOSITORY.git ./project
  echo -e "\x1b[37;43m>>ENTRYPOINT >> LOAD PULL REQUEST...\x1b[0m"

  cd $WORKDIR

  git fetch origin pull/$PULL_REQUEST_Id/head:$BRANCH
  git checkout $BRANCH
}

function initFiles {
  echo -e "\x1b[5;42;37m>>ENTRYPOINT >> FILE MODE\x1b[0m"
  sudo -E -i -u root \
    cp -avr /project "/home/bdd" > /dev/null
}

function setProjectAccess {
  sudo -E -i -u root \
    chmod -R 777 '/home/bdd'
  cd /home/bdd

  if [ ! -d "project" ]; then
    mkdir project
  fi

  export WORKDIR="/home/bdd/project"

#  if [ -n "$GIT" ]; then
#    initGit
#  else
#    initFiles
#  fi

initFiles

  sudo -E -i -u root \
    chmod -R 777 $WORKDIR
  sudo -E -i -u root \
    find $WORKDIR -type d -exec chmod 0777 {} ';'

}

setProjectAccess

#export GEOMETRY="$SCREEN_WIDTH""x""$SCREEN_HEIGHT""x""$SCREEN_DEPTH"
#export DISPLAY=:0

if [ -n "$GIT" ]; then
  export WEBPACKLOG=/$ID/webpack.log
else
  export WEBPACKLOG=$WORKDIR/webpack.log
fi


#red message
export ERRORMESSAGE="\x1b[5;41;37m>>ENTRYPOINT >> FATAL ERROR\x1b[0m"
export TIMEOUTMESSAGE="\x1b[5;41;37m>>ENTRYPOINT >> FATAL ERROR! TIMEOUT!\x1b[0m"

#clear
if [ -f "$WORKDIR/init.failed" ]; then
  rm -rf $WORKDIR/init.failed
fi
if [ -f "$WORKDIR/init.started" ]; then
  rm -rf $WORKDIR/init.started
fi
if [ -f "$WEBPACKLOG" ]; then
  rm -rf "$WEBPACKLOG"
fi

# $1 filename
function setState () {
  echo -e "$1" > $WORKDIR/$1
}
export -f setState

# $1 exit code
function shutdown () {
  echo -e "$1" > /$ID/$1

#  kill -s SIGTERM $NODE_PID
#  wait $NODE_PID
}

function info {
  echo -e "\x1b[37;43m>>ENTRYPOINT >> NODE VERSION $(node -v)\x1b[0m"
  echo -e "\x1b[37;43m>>ENTRYPOINT >> NPM VERSION $(npm -v)\x1b[0m"
  echo -e "\x1b[37;43m>>ENTRYPOINT >> YARN VERSION $(yarn --version)\x1b[0m"
}

function _yarnWatcher {
# Wait webpack
for i in $(seq 1 100)
do
  WEBPACK=$(tail -1 $WEBPACKLOG | grep 'Compiled successfully')
  echo $WEBPACK
  echo $WEBPACKLOG
  cat $WEBPACKLOG

    if [ -n "$WEBPACK" ]; then
      ## this finished away_init
      setState "init.started"
      break
    else
      WEBPACK=$(tail -1 $WEBPACKLOG | grep 'Failed')
      if [ -n "$WEBPACK" ]; then
        echo -e "\x1b[5;41;37m>>ENTRYPOINT >> FAILED TO COMPILE PROJECT\x1b[0m"
        cat $WEBPACK
        setState "init.failed"
        break
      fi
    fi

  sleep 5

  if (( $i == 99 )); then
    echo -e "\x1b[5;41;37m>>ENTRYPOINT >> FAILED YARN TIMEOUT\x1b[0m"
    setState "init.failed"
    break
  fi
done
}

function initServerOnly {
  echo -e '\E[37;44m'"\033[1m>>ENTRYPOINT >> START SERVER ONLY. SKIP COMPILE STEP\033[0m"
  cd $WORKDIR
  yarn server &> /dev/null
}

function initYarn {
# Install node_modules, run webpack compile, run yaxy proxy
  cd $WORKDIR
  yarn install
  node server.js --progress --local > $WEBPACKLOG &
  _yarnWatcher &
}

function webpackInitWatcher {
  for i in $(seq 1 100)
    do
      echo -e "\x1b[37;43m>>ENTRYPOINT >> WAITING INIT WEBPACK...\x1b[0m"
      sleep 5

      if [ -f "$WORKDIR/init.failed" ]; then
        echo -e $ERRORMESSAGE
        shutdown 1
      fi

      if [ -f "$WORKDIR/init.started" ]; then
        echo -e "\x1b[5;42;37m>>ENTRYPOINT >> WORKDIR: $WORKDIR\x1b[0m"
        echo -e "\x1b[5;42;37m>>ENTRYPOINT >> YARN: OK\x1b[0m"
        echo -e "\x1b[5;42;37m>>ENTRYPOINT >> WEBPACK: OK\x1b[0m"

#        echo -e "\x1b[5;42;37m>>ENTRYPOINT >> Network information\x1b[0m"
#        echo -e "\x1b[5;42;37m>>ENTRYPOINT >> ip route: $(ip route show)\x1b[0m"
#        echo -e "\x1b[5;42;37m>>ENTRYPOINT >> ip route: $(ip addr)\x1b[0m"

        sleep 10

        if [ -f "/$ID/@rerun.txt" ]; then

          if [ ! -d "$WORKDIR/reports" ]; then
            mkdir "$WORKDIR/reports/"
          fi

          cp "/$ID/@rerun.txt" "$WORKDIR/reports/@rerun.txt"
          rm -rf "/$ID/@rerun.txt"

#          UNCOMENT IF YOU WANT SEE THIS
#          echo -e '\E[37;44m'"\033[1m>>ENTRYPOINT >> RERUN WILL BE USE FOR RUN THREAD!\033[0m"
#          echo -e '\E[37;44m'"\033[1m>>ENTRYPOINT >> $(cat "$WORKDIR/reports/@rerun.txt")\033[0m"
        fi

        if [ -n "$RUN" ]; then
          /bin/bash -c "cd $WORKDIR && $RUN"

          isFailed=$(/bin/bash -c "cd $WORKDIR && $FAILEDPARSER");

          if [ "$isFailed" = "true" ]; then
            echo -e "\x1b[5;41;37m>>ENTRYPOINT >> BDD: FAILED! \x1b[0m"
            if [ -n "$(cat $WORKDIR/reports/@rerun.txt)" ]; then
              cp "$WORKDIR/reports/@rerun.txt" "/$ID/@rerun.txt"
            fi
            shutdown 1
            else
            echo -e '\E[37;44m'"\033[1m>>ENTRYPOINT >> BDD: ENDED!\033[0m"
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

# Set access
if [ -f "$WORKDIR/package.json" ]; then

  info

  if [ -f "$WORKDIR/public/app.bundle.js" ]; then
    echo -e '\E[37;44m'"\033[1m>>ENTRYPOINT >> FOUND COMPILED PROJECT. SKIP COMPILE STEP\033[0m"
    initServerOnly &
    setState "init.started"
  else
    initYarn
  fi

  webpackInitWatcher
else
    echo -e "\x1b[5;41;37m>>ENTRYPOINT >> FAILED package.json IS EMPTY OR NOT AVAILABILITY\x1b[0m"
    shutdown 1
fi


#wait $NODE_PID