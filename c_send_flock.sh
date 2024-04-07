#!/bin/bash
# c_send_flock.sh
# https://wiki.postgresql.org/wiki/Lock_Monitoring

MSG=$1
MESSAGE="${MSG}<BR><BR>urls:<BR>- <a href='https://wiki.colobridge.net/полезное/советы/как_исключить_повторный_запуск_скрипта'>как исключить повторный запуск скрипта</a><BR>- <a href='https://manpages.ubuntu.com/manpages/xenial/man1/flock.1.html'>flock</a><BR>"
SUBJ="ALERT: flock in cron"

if [[ -v MAILSMTP ]]; then

# MAILSMTP='smtp.inbox.ru:465'
cmdsend=$(echo "mutt -e \"set content_type=text/html\" -e \"set send_charset=utf-8\" -e \"set allow_8bit=yes\" -e \"set use_ipv6=no\" -e \"set move=no\" \
    -e \"set from=\\\"${MAILLOGIN}\\\"\" -e \"set realname=\\\"${MAILFROM}\\\"\" \
    -e \"set smtp_authenticators=\\\"login\\\"\" -e \"set smtp_url=smtps://\\\"${MAILLOGIN}\\\"@\\\"${MAILSMTP}\\\"\" -e \"set smtp_pass=\\\"${MAILPWD}\\\"\" \
    -e \"set ssl_starttls=yes\" -e \"set ssl_force_tls=yes\" -e \"set ssl_verify_dates=no\" -e \"set ssl_verify_host=no\" -s \"${SUBJ}\" ${MAILTO}")
#echo ${cmdsend}

echo -e ${MESSAGE} | mutt -e "set content_type=text/html" -e "set send_charset=utf-8" -e "set allow_8bit=yes" -e "set use_ipv6=no" -e "set move=no" -e "set copy=no" \
    -e "set from=\"${MAILLOGIN}\"" \
    -e "set realname=\"${MAILFROM}\"" -e "set smtp_authenticators=\"login\"" -e "set smtp_url=smtps://\"${MAILLOGIN}\"@\"${MAILSMTP}\"" -e "set smtp_pass=\"${MAILPWD}\"" \
    -e "set ssl_starttls=yes" -e "set ssl_force_tls=yes" -e "set ssl_verify_dates=no" -e "set ssl_verify_host=no" -s "${SUBJ}" ${MAILTO} 2>&1 | ts '[pg locks]   '
RC=$?
echo "[flock]  Send Flock '${MSG}' Alert. RC=${RC}"

fi

if [[ -v MAILSMTPURL ]]; then

# MAILSMTPURL='smtp://10.42.161.197:25'
cmdsend=$(echo "mutt -e \"set ssl_starttls=no\" -e \"set ssl_force_tls=no\" -e \"set content_type=text/html\" -e \"set send_charset=utf-8\" -e \"set allow_8bit=yes\" \
    -e \"set use_ipv6=no\" -e \"set move=no\" -e \"set from=\\\"${MAILLOGIN}\\\"\" -e \"set realname=\\\"${MAILFROM}\\\"\" -e \"set smtp_url=\\\"${MAILSMTPURL}\\\"\" \
    -s \"${SUBJ}\" ${MAILTO}")
#echo ${cmdsend}

echo -e ${MESSAGE} | mutt -e "set ssl_starttls=no" -e "set ssl_force_tls=no" -e "set content_type=text/html" -e "set send_charset=utf-8" -e "set allow_8bit=yes" \
    -e "set use_ipv6=no" -e "set move=no" -e "set copy=no" -e "set from=\"${MAILLOGIN}\"" -e "set realname=\"${MAILFROM}\"" -e "set smtp_url=\"${MAILSMTPURL}\"" \
    -s "${SUBJ}" ${MAILTO} 2>&1 | ts '[pg locks]   '
RC=$?
echo "[flock]  Send Flock '${MSG}' Alert. RC=${RC}"

fi
