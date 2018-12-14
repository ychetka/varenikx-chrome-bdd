#!/bin/bash

cd "${HOME}/src/reports"
node "${HOME}/src/node_modules/http-server/bin/http-server" -p 8099 -a 95.216.44.235  -d > /dev/null
