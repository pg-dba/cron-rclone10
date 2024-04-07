#!/bin/bash
# c_send_long_query.sh

LONGQUERYTIME='1 hour'

FILEREPORT='/cronwork/pg_long_query.html'

echo "${HOST}:${PORT}:${DBNAME}:${USERNAME}:${PASSWORD}" > /root/.pgpass
chmod 400 /root/.pgpass

CMD="SELECT count(*) \
        FROM pg_catalog.pg_stat_activity \
        WHERE state not in ('idle in transaction', 'idle in transaction (aborted)', 'idle') \
                AND (current_timestamp - query_start > interval '"${LONGQUERYTIME}"' OR current_timestamp - xact_start > interval '"${LONGQUERYTIME}"') \
                AND backend_type = 'client backend' \
    ;";

CNT=$( psql -h ${HOST} -p ${PORT} -U ${USERNAME} -d ${DBNAME} -Atq -c "${CMD}" );

CMD="WITH cte as ( \
        SELECT 'database'::text as \"database\", 'query_AGE'::text as \"query_AGE\", 'transaction_AGE'::text as \"transaction_AGE\",
                'datid'::text as datid, 'usesysid'::text as usesysid, 'pid'::text as pid, 'usename'::text as usename, 'application_name'::text as application_name,
                'client_addr'::text as client_addr, 'client_hostname'::text as client_hostname, 'client_port'::text as client_port, 'backend_start'::text as backend_start,
                'xact_start'::text as xact_start, 'query_start'::text as query_start, 'state_change'::text as state_change, 'wait_event_type'::text as wait_event_type,
                'wait_event'::text as wait_event, 'state'::text as state, 'backend_xid'::text as backend_xid, 'backend_xmin'::text as backend_xmin, 'query'::text as query,
                'backend_type'::text as backend_type \
                ,1::text as ord  \
        UNION  \
                SELECT datname::text as database, \
                age(now(),query_start)::text as "query_AGE", \
                age(now(),xact_start)::text as "transaction_AGE", \
                datid::text as datid, \
                usesysid::text as usesysid, \
                pid::text as pid, \
                usename::text as usename, \
                application_name::text as application_name, \
                client_addr::text as client_addr, \
                client_hostname::text as client_hostname, \
                client_port::text as client_port, \
                backend_start::text as backend_start, \
                xact_start::text as xact_start, \
                query_start::text as query_start, \
                state_change::text as state_change, \
                wait_event_type::text as wait_event_type, \
                wait_event::text as wait_event, \
                state::text as state, \
                backend_xid::text as backend_xid, \
                backend_xmin::text as backend_xmin, \
                query::text as query, \
                backend_type::text as backend_type, \
                2::text as ord \
                FROM pg_catalog.pg_stat_activity \
                WHERE state not in ('idle in transaction', 'idle in transaction (aborted)', 'idle') \
                AND (current_timestamp - query_start > interval '"${LONGQUERYTIME}"' OR current_timestamp - xact_start > interval '"${LONGQUERYTIME}"') \
                AND backend_type = 'client backend' \
        ) \
        SELECT \"database\", \"query_AGE\", \"transaction_AGE\", datid, usesysid, pid, usename, application_name, client_addr, client_hostname, client_port, backend_start, \
               xact_start, query_start, state_change, wait_event_type, wait_event, state, backend_xid, backend_xmin, query, backend_type \
        FROM cte \
        ORDER BY ord, query_start, xact_start \
    ;";

MSG=$( psql -h ${HOST} -p ${PORT} -U ${USERNAME} -d ${DBNAME} -Htq -c "${CMD}" 2>/dev/null | sed 's/<table border=\"1\">/<table border=\"1\" style=\"font-family:consolas;font-size:8px\">/' );

#MSGLEN=$(echo "${MSG}" | wc -l);

if [[ "${CNT}" -ne "0" ]]
then

if [[ -v MAILSMTP ]]; then

# MAILSMTP='smtp.inbox.ru:465'
cmdsend=$(echo "mutt -e \"set content_type=text/html\" -e \"set send_charset=utf-8\" -e \"set allow_8bit=yes\" -e \"set use_ipv6=no\" -e \"set move=no\" \
    -e \"set from=\\\"${MAILLOGIN}\\\"\" -e \"set realname=\\\"${MAILFROM}\\\"\" \
    -e \"set smtp_authenticators=\\\"login\\\"\" -e \"set smtp_url=smtps://\\\"${MAILLOGIN}\\\"@\\\"${MAILSMTP}\\\"\" -e \"set smtp_pass=\\\"${MAILPWD}\\\"\" \
    -e \"set ssl_starttls=yes\" -e \"set ssl_force_tls=yes\" -e \"set ssl_verify_dates=no\" -e \"set ssl_verify_host=no\" -s \"ALERT: Long Query\" ${MAILTO}")
#echo ${cmdsend}

echo ${MSG} | mutt -e "set content_type=text/html" -e "set send_charset=utf-8" -e "set allow_8bit=yes" -e "set use_ipv6=no" -e "set move=no" -e "set copy=no" \
    -e "set from=\"${MAILLOGIN}\"" \
    -e "set realname=\"${MAILFROM}\"" -e "set smtp_authenticators=\"login\"" -e "set smtp_url=smtps://\"${MAILLOGIN}\"@\"${MAILSMTP}\"" -e "set smtp_pass=\"${MAILPWD}\"" \
    -e "set ssl_starttls=yes" -e "set ssl_force_tls=yes" -e "set ssl_verify_dates=no" -e "set ssl_verify_host=no" -s "ALERT: Long Query" ${MAILTO} 2>&1 | ts '[pg long query]   '
RC=$?
echo "[pg long query]  Send Long Query Alert. RC=${RC}"

fi

if [[ -v MAILSMTPURL ]]; then

# MAILSMTPURL='smtp://10.42.161.197:25'
cmdsend=$(echo "mutt -e \"set ssl_starttls=no\" -e \"set ssl_force_tls=no\" -e \"set content_type=text/html\" -e \"set send_charset=utf-8\" -e \"set allow_8bit=yes\" \
    -e \"set use_ipv6=no\" -e \"set move=no\" -e \"set from=\\\"${MAILLOGIN}\\\"\" -e \"set realname=\\\"${MAILFROM}\\\"\" -e \"set smtp_url=\\\"${MAILSMTPURL}\\\"\" \
    -s \"ALERT: Long Query\" ${MAILTO}")
#echo ${cmdsend}

echo ${MSG} | mutt -e "set ssl_starttls=no" -e "set ssl_force_tls=no" -e "set content_type=text/html" -e "set send_charset=utf-8" -e "set allow_8bit=yes" \
    -e "set use_ipv6=no" -e "set move=no" -e "set copy=no" -e "set from=\"${MAILLOGIN}\"" -e "set realname=\"${MAILFROM}\"" -e "set smtp_url=\"${MAILSMTPURL}\"" \
    -s "ALERT: Long Query" ${MAILTO} 2>&1 | ts '[pg long query]   '
RC=$?
echo "[pg long query]  Send Long Query Alert. RC=${RC}"

fi

else

echo "[pg long query]  nothing"

fi # CNT
