#!/bin/bash
# c_send_pgbadger.sh

FileReport='/cronwork/pgbadger_report.html'
FileTmp='/cronwork/pgbadger-incremental.last'

echo "[pgbadger]  Generate Weekly Report Started."
DS=$(date +"%Y-%m-%d 00:00:00.0+03" -d "7 day ago");
DF=$(date +"%Y-%m-%d 00:00:00.0+03");
#echo "DS=${DS} DF=${DF}"; 
pgbadger --no-progressbar --wide-char --timezone +3 --jobs 1 --format csv --outfile ${FileReport} --begin "${DS}" --end "${DF}" --last-parsed ${FileTmp} \
  $(find /pglog/*.csv -type f -newermt "${DS}" ! -newermt "${DF}") 2>&1 1>/dev/null | ts '[pgbadger]   ';
RC=$?
echo "[pgbadger]  Generate Weekly Report Finished. RC=${RC}"

if [[ -v MAILSMTP ]]; then

# MAILSMTP='smtp.inbox.ru:465'
cmdsend=$(echo "mutt -e \"set content_type=text/html\" -e \"set send_charset=utf-8\" -e \"set allow_8bit=yes\" -e \"set move=no\" -e \"set use_ipv6=no\" \
  -e \"set from=\\\"${MAILLOGIN}\\\"\"  -e \"set realname=\\\"${MAILFROM}\\\"\" -e \"set smtp_authenticators=\\\"login\\\"\" \
  -e \"set smtp_url=smtps://\\\"${MAILLOGIN}\\\"@\\\"${MAILSMTP}\\\"\" 
  -e \"set smtp_pass=\\\"${MAILPWD}\\\"\" -e \"set ssl_starttls=yes\" -e \"set ssl_force_tls=yes\" -e \"set ssl_verify_dates=no\" -e \"set ssl_verify_host=no\" \
  -s \"PostgreSQL pgbadger Weekly Report\" -a ${FileReport} -- ${MAILTO}")
#echo ${cmdsend}

echo "<html>PostgreSQL on ${HOST} pgbadger Weekly Report<BR><BR>See Attachment</html>" | \
mutt -e "set content_type=text/html" -e "set send_charset=utf-8" -e "set allow_8bit=yes" -e "set move=no" -e "set copy=no" -e "set use_ipv6=no" \
  -e "set from=\"${MAILLOGIN}\"" -e "set realname=\"${MAILFROM}\"" -e "set smtp_authenticators=\"login\"" \
  -e "set smtp_url=smtps://\"${MAILLOGIN}\"@\"${MAILSMTP}\"" \
  -e "set smtp_pass=\"${MAILPWD}\"" -e "set ssl_starttls=yes" -e "set ssl_force_tls=yes" -e "set ssl_verify_dates=no" -e "set ssl_verify_host=no" \
  -s "PostgreSQL pgbadger Weekly Report" -a ${FileReport} -- ${MAILTO} | ts '[pgbadger]   '
RC=$?
echo "[pgbadger]  Send Weekly Report. RC=${RC}"

fi

if [[ -v MAILSMTPURL ]]; then

# MAILSMTPURL='smtp://10.42.161.197:25'
cmdsend=$(echo "mutt -e \"set ssl_starttls=no\" -e \"set ssl_force_tls=no\" -e \"set content_type=text/html\" -e \"set send_charset=utf-8\" \
  -e \"set allow_8bit=yes\" -e \"set use_ipv6=no\" \
  -e \"set from=\\\"${MAILLOGIN}\\\"\" -e \"set realname=\\\"${MAILFROM}\\\"\" -e \"set smtp_url=\\\"${MAILSMTPURL}\\\"\" \
  -s \"PostgreSQL pgbadger Weekly Report\" -a ${FileReport} -- ${MAILTO}")
#echo ${cmdsend}

echo "<html>PostgreSQL on ${HOST} pgbadger Weekly Report<BR><BR>See Attachment</html>" | \
mutt -e "set ssl_starttls=no" -e "set ssl_force_tls=no" -e "set content_type=text/html" -e "set send_charset=utf-8" \
  -e "set allow_8bit=yes" -e "set use_ipv6=no" -e "set move=no" -e "set copy=no" \
  -e "set from=\"${MAILLOGIN}\"" -e "set realname=\"${MAILFROM}\"" -e "set smtp_url=\"${MAILSMTPURL}\"" \
  -s "PostgreSQL pgbadger Weekly Report" -a ${FileReport} -- ${MAILTO}
RC=$?
echo "[pgbadger]  Send Weekly Report. RC=${RC}"

fi
