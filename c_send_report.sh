#!/bin/bash
# c_send_report.sh

FILEREPORT='/cronwork/pg_profile_daily.html'
REPORTNAME="Daily Report"
SUBJTEXT="PostgreSQL [${HOST}] pg_profile ${REPORTNAME}"
HEADTEXT='<html><head><meta charset="utf-8"></head><body><p style="font-family:Monospace;font-size:10px"><a href="https://postgrespro.ru/docs/postgrespro/13/pgpro-pwr#PGPRO-PWR-SECTIONS-OF-A-REPORT">Описание разделов отчёта</a> <a href="https://github.com/zubkov-andrei/pg_profile/blob/master/doc/pg_profile.md#sections-of-a-report">Description of report sections</a></p></body></html>'

rm -f ${FILEREPORT}

PGPASSWORD=${PASSWORD} psql -h ${HOST} -p ${PORT} -U ${USERNAME} -d ${DBNAME} -qAt -c "SELECT profile.report_daily();" --output="${FILEREPORT}"
RC=$?
echo "[pg_profile]  Generate ${REPORTNAME}. RC=${RC}"

if [[ ( ! -f ${FILEREPORT} ) || ( ! -s ${FILEREPORT} ) ]]; then
RC=-1
echo "[pg_profile]  Report is zero. RC=${RC}"
exit ${RC}
fi

sed -i "1i${HEADTEXT}" ${FILEREPORT}

sed -i 's/<H2>Report sections<\/H2>/<H2><a NAME=report_sec>Report sections<\/H2>/gi' ${FILEREPORT}
sed -i 's/<\/a><\/H3>/<\/a> <a HREF=#report_sec><button>up to contents<\/button><\/a><\/H3>/g' ${FILEREPORT}

PGPASSWORD=${PASSWORD} psql -h ${HOST} -p ${PORT} -U ${USERNAME} -d ${DBNAME} -xtA -c "SELECT pg_stat_statements_reset();" 2>&1 | sed -n '1p' | ts '[pg_profile]   '
RC=$?
echo "[pg_profile]  Reset Statements Stats. RC=${RC}"

PGPASSWORD=${PASSWORD} psql -h ${HOST} -p ${PORT} -U ${USERNAME} -d ${DBNAME} -xtA -c "SELECT pg_stat_reset_shared('bgwriter');" 2>&1 | sed -n '1p' | ts '[pg_profile]   '
RC=$?
echo "[pg_profile]  Reset bgWriter Stats. RC=${RC}"

if [[ -v MAILSMTP ]]; then

# MAILSMTP='smtp.inbox.ru:465'
cmdsend=$(echo "mutt -e \"set content_type=text/html\" -e \"set send_charset=utf-8\" -e \"set allow_8bit=yes\" -e \"set use_ipv6=no\" \
  -e \"set move=no\" -e \"set copy=no\" \
  -e \"set from=\\\"${MAILLOGIN}\\\"\" -e \"set realname=\\\"${MAILFROM}\\\"\" \
  -e \"set smtp_authenticators=\\\"login\\\"\" -e \"set smtp_url=smtps://\\\"${MAILLOGIN}\\\"@\\\"${MAILSMTP}\\\"\" -e \"set smtp_pass=\\\"${MAILPWD}\\\"\" \
  -e \"set ssl_starttls=yes\" -e \"set ssl_force_tls=yes\" -e \"set ssl_verify_dates=no\" -e \"set ssl_verify_host=no\" \
  -s \"${SUBJTEXT}\" ${MAILTO}")
#echo ${cmdsend}

rm -f /root/.muttdebug0

cat ${FILEREPORT} | mutt -d3 -e "set content_type=text/html" -e "set send_charset=utf-8" -e "set allow_8bit=yes" -e "set use_ipv6=no" \
  -e "set move=no" -e "set copy=no" \
  -e "set from=\"${MAILLOGIN}\"" -e "set realname=\"${MAILFROM}\"" \
  -e "set smtp_authenticators=\"login\"" -e "set smtp_url=smtps://\"${MAILLOGIN}\"@\"${MAILSMTP}\"" -e "set smtp_pass=\"${MAILPWD}\"" \
  -e "set ssl_starttls=yes" -e "set ssl_force_tls=yes" -e "set ssl_verify_dates=no" -e "set ssl_verify_host=no" \
  -s "${SUBJTEXT}" ${MAILTO} 2>&1 | ts '[pg_profile]   '
RC=$?
echo "[pg_profile]  Send ${REPORTNAME}. RC=${RC}"

fi

if [[ -v MAILSMTPURL ]]; then

# MAILSMTPURL='smtp://10.42.161.197:25'
cmdsend=$(echo "mutt -e \"set ssl_starttls=no\" -e \"set ssl_force_tls=no\" -e \"set content_type=text/html\" -e \"set send_charset=utf-8\" \
  -e \"set allow_8bit=yes\" -e \"set use_ipv6=no\" -e \"set move=no\" -e \"set copy=no\" \
  -e \"set from=\\\"${MAILLOGIN}\\\"\" -e \"set realname=\\\"${MAILFROM}\\\"\" -e \"set smtp_url=\\\"${MAILSMTPURL}\\\"\" \
  -s \"${SUBJTEXT}\" ${MAILTO}")
#echo ${cmdsend}

rm -f /root/.muttdebug0

cat ${FILEREPORT} | mutt -d3 -e "set ssl_starttls=no" -e "set ssl_force_tls=no" -e "set content_type=text/html" -e "set send_charset=utf-8" \
  -e "set allow_8bit=yes" -e "set use_ipv6=no" -e "set move=no" -e "set copy=no" \
  -e "set from=\"${MAILLOGIN}\"" -e "set realname=\"${MAILFROM}\"" -e "set smtp_url=\"${MAILSMTPURL}\"" \
  -s "${SUBJTEXT}" ${MAILTO} 2>&1 | ts '[pg_profile]   '
RC=$?
echo "[pg_profile]  Send ${REPORTNAME}. RC=${RC}"

fi
