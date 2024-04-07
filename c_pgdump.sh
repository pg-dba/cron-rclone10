#!/bin/bash
# c_pgdump.sh
# need backups directory mapped /pgbackups
# если определён ZBX_SERVERS, то шлёт статистику в Zabbix

TRANSFERSTOP=0

# если параметров 1 или 2 ,и второй только из цифр
if [[ ("$#" -eq 1) || ( ("$#" -eq 2) && ($2 =~ ^[[:digit:]]+$) ) ]]; then

backupDatabase=$1
#backupName="${backupDatabase}_$(date +%FT%T%z).dump"
backupName="${backupDatabase}_$(date +%A).dump"

zbxskey='pgsql.pg_dump.backup.start["'${backupDatabase}'"]'
zbxfkey='pgsql.pg_dump.backup.finish["'${backupDatabase}'"]'
zbxrkey='pgsql.pg_dump.backup.rotation["'${backupDatabase}'"]'
zbxtkey='pgsql.pg_dump.backup.time["'${backupDatabase}'"]'
zbxckey='pgsql.pg_dump.backup.rc["'${backupDatabase}'"]'
zbxnkey='pgsql.pg_dump.transfer.rc["'${backupDatabase}'"]'
zbxikey='pgsql.pg_dump.transfer.time["'${backupDatabase}'"]'
zbxhkey='pgsql.pg_dump.transfer.finish["'${backupDatabase}'"]'

echo "[pgdump]  [${backupDatabase}] backup started"
bkp_start=$(date +%s)
if [ -n "${ZBX_SERVERS}" ]; then
#zabbix_sender -z ${ZBX_SERVERS} -p ${ZBX_PORT} -s ${ZBX_HOST} -k "${zbxskey}" -o "$(date --iso-8601=seconds)" 2>&1 1>/dev/null
zabbix_sender -z ${ZBX_SERVERS} -p ${ZBX_PORT} -s ${ZBX_HOST} -k "${zbxskey}" -o "${bkp_start}" 2>&1 1>/dev/null
fi

PGPASSWORD=${PASSWORD} pg_dump -h ${HOST} -p ${PORT} -U ${USERNAME} -Fc -f "/pgbackups/${backupName}" "${backupDatabase}" 2>&1
RC=$?

echo "[pgdump]  [${backupDatabase}] backup finished. RC=${RC}"
bkp_finish=$(date +%s)

if [ -n "${ZBX_SERVERS}" ]; then
zabbix_sender -z ${ZBX_SERVERS} -p ${ZBX_PORT} -s ${ZBX_HOST} -k "${zbxckey}" -o "${RC}" 2>&1 1>/dev/null
#zabbix_sender -z ${ZBX_SERVERS} -p ${ZBX_PORT} -s ${ZBX_HOST} -k "${zbxfkey}" -o "$(date --iso-8601=seconds)" 2>&1 1>/dev/null
zabbix_sender -z ${ZBX_SERVERS} -p ${ZBX_PORT} -s ${ZBX_HOST} -k "${zbxfkey}" -o "${bkp_finish}" 2>&1 1>/dev/null
zabbix_sender -z ${ZBX_SERVERS} -p ${ZBX_PORT} -s ${ZBX_HOST} -k "${zbxtkey}" -o "$((${bkp_finish}-${bkp_start}))" 2>&1 1>/dev/null
fi

if [[ ${RC} -ne 0 ]]; then
rm -f /pgbackups/${backupName}
echo "[pgdump]  backup file [${backupName}] deleted."
fi

if [[ ("$#" -eq 2) && (${RC} -eq 0) ]]; then

saves=$2

rm -f $(ls -1t --time-style=long-iso /pgbackups/${backupDatabase}_*.dump 2>/dev/null | sed -n "$((${saves}+1)),\$p") 2>&1 1>/dev/null

echo "[pgdump]  [${backupDatabase}] backup file $2 rotation completed."

if [ -n "${ZBX_SERVERS}" ]; then
zabbix_sender -z ${ZBX_SERVERS} -p ${ZBX_PORT} -s ${ZBX_HOST} -k "${zbxrkey}" -o "${saves}" 2>&1 1>/dev/null
fi

fi


if [ ${TRANSFERSTOP} -eq 0 ]; then
if [ -n "${MINIO_ENDPOINT_URL}" ]; then

echo "[pgdump]  [${backupDatabase}] transfer started"
tr_start=$(date +%s)

mc cp "/pgbackups/${backupName}" minio/${MINIO_BUCKET}/ 2>&1 1>/dev/null
RC=$?

echo "[pgdump]  [${backupDatabase}] transfer finished. RC=${RC}"
tr_finish=$(date +%s)

if [ -n "${ZBX_SERVERS}" ]; then
zabbix_sender -z ${ZBX_SERVERS} -p ${ZBX_PORT} -s ${ZBX_HOST} -k "${zbxnkey}" -o "${RC}" 2>&1 1>/dev/null
zabbix_sender -z ${ZBX_SERVERS} -p ${ZBX_PORT} -s ${ZBX_HOST} -k "${zbxikey}" -o "$((${tr_finish}-${tr_start}))" 2>&1 1>/dev/null
zabbix_sender -z ${ZBX_SERVERS} -p ${ZBX_PORT} -s ${ZBX_HOST} -k "${zbxhkey}" -o "${tr_finish}" 2>&1 1>/dev/null
fi

fi
fi

fi

exit ${RC}
