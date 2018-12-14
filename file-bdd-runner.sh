#!/bin/bash

##$1 directory with project
##$2 features group - support tags and filter
##$3 id
##$4 apiHost
##$5 REPORT_PATCH

ID=
PROJECT_DIRECTORY=
API_HOST=
ABSOLUTE_REPORT_DIRECTORY=$5
COMMAND=
FAILED_PARSER=


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


if [ "${2}" = "@all" ]; then
  COMMAND="yarn run test:bdd --reportsDirectory=\"${RELATIVE_REPORT_DIRECTORY}\" --reportId=\"${ID}\" --silentMode=true --useLocalProxy=true --apiHost=\"${API_HOST}\""
else
  SETTING=$(echo "${2}"| cut -d':' -f 1)
  VALUE=$(echo "${2}"| cut -d':' -f 2)
  COMMAND="yarn run test:bdd --reportsDirectory=\"${RELATIVE_REPORT_DIRECTORY}\" --reportId=\"${ID}\" --silentMode=true --useLocalProxy=true --${SETTING} \"${VALUE}\" --apiHost=\"${API_HOST}\""
fi

echo -e '\E[37;44m'"\033[1m YARN COMMAND ${COMMAND} \033[0m"
/bin/bash -c "${COMMAND}"

isFailed=$(/bin/bash -c "${FAILED_PARSER} --patch=\"${ABSOLUTE_REPORT_DIRECTORY}/${ID}.report.json\"")

if [ "${isFailed}" = "true" ]; then

  echo -e "\x1b[5;41;37m THREAD BDD: FAILED!\x1b[0m"
  sqlite3 -init <(echo ".timeout 3000") ${ABSOLUTE_REPORT_DIRECTORY}/test.db "UPDATE THREAD_STATUSES SET STATUS= '1' WHERE THREAD_ID= '${ID}';"
  exit 1

else

  echo -e '\E[37;44m'"\033[1mTHREAD BDD: ENDED!\033[0m"
  sqlite3 -init <(echo ".timeout 3000") ${ABSOLUTE_REPORT_DIRECTORY}/test.db "UPDATE THREAD_STATUSES SET STATUS= '0' WHERE THREAD_ID= '${ID}';"
  exit 0

fi


