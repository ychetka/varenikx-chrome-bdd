#!/bin/bash

cd "$HOME/src"
sudo kill -9 $(ps aux | grep yaxy | awk '{print $2}') > /dev/null
yarn run server & > /dev/null
#yarn run yaxy --config "$HOME/src/yaxy-config.txt" --port 8558