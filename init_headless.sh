#!/bin/bash
export GEOMETRY="$SCREEN_WIDTH""x""$SCREEN_HEIGHT""x""$SCREEN_DEPTH"
export RESOLUTION="\x1b[5;42;37mDISPLAY RESOLUTION""$GEOMETRY""\x1b[0m"
export DISPLAY=:0

function shutdownXVFB () {
  kill -s SIGTERM $NODE_PID
  wait $NODE_PID
}

# Install yarn
npm install yarn -g >$NPMLOG

# Started Xvfb
Xvfb $DISPLAY -screen 0 $GEOMETRY >$XVFBLOG &

NODE_PID=$!

fluxbox -display $DISPLAY >$FLUXBOXLOG &
x11vnc -display $DISPLAY -bg -nopw -xkb -usepw -shared -repeat -loop -forever >$X11VNCLOG &

# Install node_modules, run webpack compile, run yaxy proxy 
yarn install >$YARNLOG
yarn run wds > $WEBPACKLOG &

# Wait webpack 
for i in $(seq 1 100)
do
  WEBPACK=$(tail -1 $WEBPACKLOG | grep Compiled)
  YARN=$(tail -1 $YARNLOG | grep Done)
  XDPY=$(xdpyinfo -display $DISPLAY)

  xdpyinfo -display $DISPLAY >/dev/null 2>&1
  if [ $? -eq 0 ]; then
      if [ -n "$WEBPACK" ] && [ -n "$YARN" ]; then
        ## this finished away_init
        setState "init.started"
        break
      else
        WEBPACK=$(tail -1 $WEBPACKLOG | grep Failed)
        YARN=$(tail -1 $YARNLOG | grep -v Done)

        if [ -n "$WEBPACK" ]; then
          echo -e "\x1b[5;41;37mFailed WEBPACK\x1b[0m"
          setState "init.failed"
          break
        fi
        if [ -n "$WEBPACK" ] || [ -n "$YARN" ]; then
          echo -e "\x1b[5;41;37mFailed YARN\x1b[0m"
          setState "init.failed"
          break
        fi
      fi
  fi

  sleep 3
  if [ i = 99 ]; then
    echo -e "\x1b[5;41;37mFailed TIMEOUT\x1b[0m"
    setState "init.failed"
    break
  fi
done

wait $NODE_PID
