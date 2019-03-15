#!/bin/bash

##$1 directory with project
##$2 features group - support tags and filter
##$3 id
##$4 apiHost
##$5 REPORT_PATCH
##$6 THREAD_DEBUG_PORT

ID=
PROJECT_DIRECTORY=
API_HOST=
ABSOLUTE_REPORT_DIRECTORY=$5
COMMAND=
FAILED_PARSER=
THREAD_DEBUG_PORT=$6


if (( DEBUG == "1" )); then
    echo "1 ${1}"
    echo "2 ${2}"
    echo "3 ${3}"
    echo "4 ${4}"
    echo "5 ${5}"
    echo "6 ${6}"
fi

PROJECT_NODE_VERSION="v8.11.2"
source ~/.nvm/nvm.sh &> /dev/null
nvm install ${PROJECT_NODE_VERSION} &> /dev/null
nvm use ${PROJECT_NODE_VERSION} &> /dev/null
nvm alias default ${PROJECT_NODE_VERSION} &> /dev/null
npm install yarn -g &> /dev/null

if [ -n "${4}" ]; then
  API_HOST=$4
else
  API_HOST="demo.optimacros.com"
fi

PROJECT_DIRECTORY=$1
RELATIVE_REPORT_DIRECTORY="reports"
FAILED_PARSER="node ${PROJECT_DIRECTORY}/bin/cucumber-failed-parser.js"
ID=$3

cd ${PROJECT_DIRECTORY}

function forceBreakScript {
  echo -e "THREAD BDD FAILED, ${API_HOST} Offline"
  sqlite3 -init <(echo ".timeout 3000") ${ABSOLUTE_REPORT_DIRECTORY}/test.db "UPDATE THREAD_STATUSES SET STATUS= '1' WHERE THREAD_ID= '${ID}';"
  exit 1
}

#need test api host
nc -vz -w 5 ${API_HOST} 80 &> /dev/null && echo "${API_HOST} is online" || forceBreakScript

if [ "${2}" = "@all" ]; then
  COMMAND="yarn run test:bdd --reportsDirectory=\"${RELATIVE_REPORT_DIRECTORY}\" --reportId=\"${ID}\" --silentMode=true --useLocalProxy=true --apiHost=\"${API_HOST}\" --remoteDebugPort=\"${THREAD_DEBUG_PORT}\""
else
  SETTING=$(echo "${2}"| cut -d':' -f 1)
  VALUE=$(echo "${2}"| cut -d':' -f 2)
  COMMAND="yarn run test:bdd --reportsDirectory=\"${RELATIVE_REPORT_DIRECTORY}\" --reportId=\"${ID}\" --silentMode=true --useLocalProxy=true --${SETTING} \"${VALUE}\" --apiHost=\"${API_HOST}\" --remoteDebugPort=\"${THREAD_DEBUG_PORT}\""
fi

echo -e "YARN COMMAND ${COMMAND}"
/bin/bash -c "${COMMAND}"

isFailed=$(/bin/bash -c "${FAILED_PARSER} --patch=\"${ABSOLUTE_REPORT_DIRECTORY}/${ID}.report.json\"")

if [ "${isFailed}" = "true" ]; then
  echo -e "THREAD BDD FAILED"

  sqlite3 -init <(echo ".timeout 3000") ${ABSOLUTE_REPORT_DIRECTORY}/test.db "UPDATE THREAD_STATUSES SET STATUS= '1' WHERE THREAD_ID= '${ID}';"
  exit 1
else
  echo -e "THREAD BDD ENDED"

  sqlite3 -init <(echo ".timeout 3000") ${ABSOLUTE_REPORT_DIRECTORY}/test.db "UPDATE THREAD_STATUSES SET STATUS= '0' WHERE THREAD_ID= '${ID}';"
  exit 0
fi
