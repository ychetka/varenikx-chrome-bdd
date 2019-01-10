#!/bin/bash

SERVER_LOG_FILE=$1

cd "$HOME/src"
yarn run server > "${SERVER_LOG_FILE}"