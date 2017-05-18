#!/bin/bash
export GEOMETRY="$SCREEN_WIDTH""x""$SCREEN_HEIGHT""x""$SCREEN_DEPTH"
export RESOLUTION="\x1b[5;42;37mDISPLAY RESOLUTION""$GEOMETRY""\x1b[0m"

export YARNLOG="$HOME/yarn.log"
export NPMLOG="$HOME/npm.log"
export WEBPACKLOG="$HOME/webpack.log"

function shutdown {
  kill -s SIGTERM $NODE_PID
  wait $NODE_PID
}

export DISPLAY=:0

if [ -d /project/ ]; then
  if [ -f /project/package.json ]; then
    chmod 777 /project
    chmod -R 777 /project/*
    find /project -type d -exec chmod 0777 {} ';'
    cd /project
    export WORKDIR="/project"
  fi
fi

wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | bash >/dev/null
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install 7.10.0 && nvm use 7.10.0 && npm install yarn -g >$NPMLOG
yarn install >$YARNLOG
Xvfb $DISPLAY -screen 0 $GEOMETRY 1>/dev/null &

NODE_PID=$!

for i in $(seq 1 10)
do
  xdpyinfo -display $DISPLAY >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo -e "\x1b[5;42;37mXvfb started\x1b[0m"
    break
  fi
  echo "\x1b[37;43mwaiting Xvfb...\x1b[0m"
  sleep 1
done

fluxbox -display $DISPLAY >/dev/null &
x11vnc -display $DISPLAY -bg -nopw -xkb -usepw -shared -repeat -loop -forever >/dev/null &

echo -e $RESOLUTION
echo -e "\x1b[5;42;37mYou must connect with VNC client\x1b[0m"
echo -e "\x1b[37;43msystem\x1b[0m $(lsb_release -a)"
echo -e "\x1b[37;43mnode version\x1b[0m $(node -v)"
echo -e "\x1b[37;43mnpm version\x1b[0m $(npm -v)"
echo -e "\x1b[37;43mxvfb\x1b[0m $(apt-cache show xvfb | grep -i version)"
echo -e "\x1b[37;43mgoogle-chrome-stable\x1b[0m $(apt-cache show google-chrome-stable | grep -i version)"
echo -e "\x1b[37;43myarn version\x1b[0m $(yarn --version)"
echo -e "$(java -version)"
sleep 2

yarn run wds >$WEBPACKLOG &

for i in $(seq 1 100)
do
  endline=$(tail -1 $WEBPACKLOG)
  if [ "$endline" == "webpack: Compiled successfully." ]; then
    echo -e "\x1b[5;42;37mRun bdd tests\x1b[0m"
    echo -e "\x1b[5;42;37mWebpack: Compiled successfully\x1b[0m"
    yarn test:spec
    break
  fi
  if [ "$endline" == "webpack: Failed to compile." ]; then
    echo -e "Webpack: Failed to compile."
    cat ./webpack.log
    break
  fi
  echo -e "\x1b[37;43mwaiting webpack...\x1b[0m"
  sleep 3
done

wait $NODE_PID
