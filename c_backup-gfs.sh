#!/bin/bash
# c_backup-gfs.sh

# run: backup-gfs.sh source_file destination_directory
# run: ./backup-gfs.sh /pgbackups/pg_profile--4.1.tar.gz rclone/dev/myappstack/postgres3
# run: rclone ls minio:rclone/dev/myappstack/postgres3
# need: RCLONE_S3_NO_CHECK_BUCKET=true
# may be: RCLONE_BWLIMIT=5M

if [[ "$#" -eq 2 ]]; then

source_file=$1
destination_directory=$2

env|grep RCLONE | ts '[rclone]   '
#echo "${source_file}"
#echo "${destination_directory}"

rotation_yearly="1y"
rotation_monthly="12M"
rotation_weekly="5w"
rotation_daily="14d"

#DTC=$(date -d '2024-01-01' +%F)
DTC=$(date +%F)

# https://rclone.org/commands/rclone_config_dump/
# rclone config dump
# rclone listremotes
# https://rclone.org/commands/rclone_copy/
# rclone copy source:sourcepath dest:destpath
# rclone copy --max-age 24h --no-traverse /path/to/src remote:
# https://rclone.org/commands/rclone_ls/
# rclone ls minio:rclone/dev/myappstack/postgres3
# https://rclone.org/commands/rclone_lsf/
# rclone lsf  --format "tsp" minio:rclone/dev/myappstack/postgres3/weekly/
# https://rclone.org/commands/rclone_delete/
# rclone delete minio:rclone --min-age 24h --dry-run # удалить старее 24 hour
# https://rclone.org/docs/#time-option
# A duration string is a possibly signed sequence of decimal numbers, each with optional fraction and a unit suffix, such as "300ms", "-1.5h" or "2h45m".
# Default units are seconds or the following abbreviations are valid:
# ms - Milliseconds
# s - Seconds
# m - Minutes
# h - Hours
# d - Days
# w - Weeks
# M - Months
# y - Years
# флаг --dry-run для тестирования без копирования чего-либо.
# rclone delete minio:rclone --min-age 2w --dry-run # при этом дата выводится текущая, а не дата измменения файла
# rclone delete minio:rclone/dev/myappstack/postgres3/weekly --min-age 2w --dry-run
#--------------------------------------------------------------------------------------------------------------------------
#DTS=$(date -d ${start_date} +%F)
#DTC=$(date +%F)
#DTdays=$(($(($(date -d ${DTC} +%s)-$(date -d ${DTS} +%s)))/(60*60*24)))
# select (DATEPART(dw, @dt) + @@datefirst - 2)%7+1
# linux $(date +%u)=7 = sunday

# Warning: running mkdir on a remote which can't have empty directories does nothing
# rclone mkdir minio:${destination_directory}/yearly    # пишется 1 числа каждого года.
# rclone mkdir minio:${destination_directory}/monthly   # пишется 1 числа каждого месяца.
# rclone mkdir minio:${destination_directory}/weekly    # пишется по вс
# rclone mkdir minio:${destination_directory}/daily     # пишется ежедневно c пн до cб, если не попадает в другие.
#                                                         Ротация: в пн зачищается перед записью или удаляются старее N дней.

if [[ "$(date -d ${DTC} +%j)" == "001" ]]; then
# начало года
rclone copy ${source_file} minio:${destination_directory}/yearly/
RC=$?
rclone delete minio:${destination_directory}/yearly/ --min-age ${rotation_yearly}
elif [[ "$(date -d ${DTC} +%d)" == "01" ]]; then
# начало месяца
rclone copy ${source_file} minio:${destination_directory}/monthly/
RC=$?
rclone delete minio:${destination_directory}/monthly/ --min-age ${rotation_monthly}
elif [[ "$(date -d ${DTC} +%u)" == "7" ]]; then
# воскресенье
rclone copy ${source_file} minio:${destination_directory}/weekly/
RC=$?
rclone delete minio:${destination_directory}/weekly/ --min-age ${rotation_weekly}
else
# пн-сб, и не начало месяца, и не начало года
rclone copy ${source_file} minio:${destination_directory}/daily/
RC=$?
rclone delete minio:${destination_directory}/weekly/ --min-age ${rotation_daily}
fi

#--------------------------------------------------------------------------------------------------------------------------
else
RC=1
echo -e "Usage:\n c_backup-gfs.sh source_file destination_directory"
fi

exit ${RC}
