#!/usr/bin/env bash

# Rancher DNS
if [ ! -z "${DNSSERVER}" ]; then
echo "nameserver ${DNSSERVER}" > /etc/resolv.conf
fi

# cron timezone
if [ ! -z "${TZ}" ]; then
ln -snf /usr/share/zoneinfo/$TZ /etc/localtime
echo ${TZ} > /etc/timezone
fi

mkdir -p /root/.config/rclone
touch /root/.config/rclone/rclone.conf
truncate -s 0 /root/.config/rclone/rclone.conf
chmod 600 /root/.config/rclone/rclone.conf

# minio
if [ ! -z "${MINIO_ENDPOINT_URL}" ]; then
echo -e "\n[minio]" >> /root/.config/rclone/rclone.conf
echo "type = s3" >> /root/.config/rclone/rclone.conf
echo "provider = Minio" >> /root/.config/rclone/rclone.conf
echo "env_auth = true" >> /root/.config/rclone/rclone.conf
echo "access_key_id = ${MINIO_ACCESS_KEY_ID}" >> /root/.config/rclone/rclone.conf
echo "secret_access_key = ${MINIO_SECRET_ACCESS_KEY}" >> /root/.config/rclone/rclone.conf
echo "no_check_bucket = true" >> /root/.config/rclone/rclone.conf
echo "region = us-east-1" >> /root/.config/rclone/rclone.conf
echo "endpoint = ${MINIO_ENDPOINT_URL}" >> /root/.config/rclone/rclone.conf
echo "location_constraint =" >> /root/.config/rclone/rclone.conf
echo "server_side_encryption =" >> /root/.config/rclone/rclone.conf
# rclone sync /cronwork minio:${MINIO_BUCKET}/${HOSTNAME} --progress
# rclone lsd minio:
# rclone ls minio:${MINIO_BUCKET}/${HOSTNAME}
fi

# sftp
if [ ! -z "${SFTPSERVER}" ]; then
echo -e "\n[sftp]" >> /root/.config/rclone/rclone.conf
echo "type = sftp" >> /root/.config/rclone/rclone.conf
echo "host = ${SFTPSERVER}" >> /root/.config/rclone/rclone.conf
echo "user = ${SFTPUSER}" >> /root/.config/rclone/rclone.conf
echo "pass = $(rclone obscure ${SFTPPASSWORD})" >> /root/.config/rclone/rclone.conf
fi

# YandexStorage
if [[ (! -z "${YandexStorage_access_key_id}") && (! -z "${YandexStorage_secret_access_key}") ]]; then
echo -e "\n[YandexStorage]" >> /root/.config/rclone/rclone.conf
echo "type = s3" >> /root/.config/rclone/rclone.conf
echo "provider = Other" >> /root/.config/rclone/rclone.conf
echo "access_key_id = ${YandexStorage_access_key_id}" >> /root/.config/rclone/rclone.conf
echo "secret_access_key = ${YandexStorage_secret_access_key}" >> /root/.config/rclone/rclone.conf
echo "region = ru-central1" >> /root/.config/rclone/rclone.conf
echo "endpoint = https://storage.yandexcloud.net" >> /root/.config/rclone/rclone.conf
echo "acl = private" >> /root/.config/rclone/rclone.conf
# rclone ls YandexStorage:${YandexStorage_BUCKET}/DEV
fi

# logrotate
echo "/etc/cron.d/rclone.log" > /etc/logrotate.d/crontask
echo "{" >> /etc/logrotate.d/crontask
echo -e "\tdaily" >> /etc/logrotate.d/crontask
echo -e "\tmissingok" >> /etc/logrotate.d/crontask
echo -e "\tnocreate" >> /etc/logrotate.d/crontask
echo -e "\tnotifempty" >> /etc/logrotate.d/crontask
echo -e "\trotate 7" >> /etc/logrotate.d/crontask
echo -e "\tnocompress" >> /etc/logrotate.d/crontask
echo "}" >> /etc/logrotate.d/crontask
chmod 644 /etc/logrotate.d/crontask

set -e

# переносим значения переменных из текущего окружения
env | while read -r LINE; do  # читаем результат команды 'env' построчно
    # делим строку на две части, используя в качестве разделителя "=" (см. IFS)
    IFS="=" read VAR VAL <<< ${LINE}
    # удаляем все предыдущие упоминания о переменной, игнорируя код возврата
    sed --in-place "/^${VAR}/d" /etc/security/pam_env.conf || true
    # добавляем определение новой переменной в конец файла
    echo "${VAR} DEFAULT=\"${VAL}\"" >> /etc/security/pam_env.conf
done

if [[ (-n ${MINIO_ENDPOINT_URL}) && (-n ${MINIO_ACCESS_KEY_ID}) && (-n ${MINIO_SECRET_ACCESS_KEY}) && (-n ${MINIO_BUCKET}) ]]; then
mc config --quiet host add minio ${MINIO_ENDPOINT_URL} ${MINIO_ACCESS_KEY_ID} ${MINIO_SECRET_ACCESS_KEY} 2>&1 1>/dev/null
fi

exec "$@"
