#!/bin/bash

#example sudo ./reports/install-report-service.sh 127.0.0.1 8099 /home/bdd/reports /home/bdd/src/reports

SERVICE_IP=$1
SERVICE_PORT=$2
ARCHIVE_REPORTS_DIRECTORY=$3
LAST_REPORTS_DIRECTORY=$4
LAST_REPORTS_DIRECTORY_NAME="LAST"

if [ ! -d "${ARCHIVE_REPORTS_DIRECTORY}" ]; then
  mkdir "${ARCHIVE_REPORTS_DIRECTORY}"
  chmod 0777 "${ARCHIVE_REPORTS_DIRECTORY}"
  mkdir "${ARCHIVE_REPORTS_DIRECTORY}/${LAST_REPORTS_DIRECTORY_NAME}"
  chmod 0777 "${ARCHIVE_REPORTS_DIRECTORY}/${LAST_REPORTS_DIRECTORY_NAME}"
fi

if [ ! -d "${LAST_REPORTS_DIRECTORY}" ]; then
  mkdir "${LAST_REPORTS_DIRECTORY}"
  chmod 0777 ${LAST_REPORTS_DIRECTORY}
fi

apt install webfs

rm -f "/etc/webfsd.conf"

cat <<EOT >> "/etc/webfsd.conf"
web_root="${ARCHIVE_REPORTS_DIRECTORY}"
web_host=""
web_ip="${SERVICE_IP}"
web_port="${SERVICE_PORT}"
web_virtual="false"
web_timeout=""
web_conn=""
web_index=""
web_dircache=""
web_accesslog=""
web_logbuffering="true"
web_syslog="false"
web_user="www-data"
web_group="www-data"
web_cgipath=""
web_extras="-b bdd:bdd"
EOT

ln -s /${LAST_REPORTS_DIRECTORY} /${ARCHIVE_REPORTS_DIRECTORY}/${LAST_REPORTS_DIRECTORY_NAME}

service webfs stop
service webfs start





