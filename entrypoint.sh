#!/bin/bash
export WORKDIR="./"

# $1 filename
function setState () {
  echo -e "$1" > $WORKDIR/$1
}
export -f setState

# Set access
if [ -d "/project/" ]; then
  if [ -f "/project/package.json" ]; then
    chmod 777 /project
    chmod -R 777 /project/*
    find /project -type d -exec chmod 0777 {} ';'
    cd /project
    export WORKDIR="/project"
  else 
    setState 'init.failed'
    exit 1
  fi
else
  if [ -f "./package.json" ]; then
    WORKDIR="./"
  else
    setState 'init.failed'
  fi
fi

export X11VNCLOG=$WORKDIR/x11vnc.log
export FLUXBOXLOG=$WORKDIR/fluxbox.log
export XVFBLOG=$WORKDIR/xvfb.log
export YARNLOG=$WORKDIR/yarn.log
export NPMLOG=$WORKDIR/npm.log
export WEBPACKLOG=$WORKDIR/webpack.log

#red message
export ERRORMESSAGE="\x1b[5;41;37mFatal Error\x1b[0m"
export TIMEOUTMESSAGE="\x1b[5;41;37mFatal Error! Timeout!\x1b[0m"

# $1 filename
function catLog () {
  #orange
  echo -e 'x11vnc.log'
  cat $X11VNCLOG

  echo -e 'fluxbox.log'
  cat $FLUXBOXLOG

  echo -e 'xvfb.log'
  cat $XVFBLOG

  echo -e 'yarn.log'
  cat $YARNLOG

  echo -e 'npm.log'
  cat $NPMLOG

  echo -e 'webpack.log'
  cat $WEBPACKLOG
}
export -f catLog

/init_headless.sh &
/away_init.sh



