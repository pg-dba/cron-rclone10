#!/bin/bash
# c_send_locks.sh

LOCKTIMEOUT='1 minutes'

FILEREPORT='/cronwork/pg_profile_daily.html'

echo "${HOST}:${PORT}:${DBNAME}:${USERNAME}:${PASSWORD}" > /root/.pgpass
chmod 400 /root/.pgpass

CMD="SELECT count(*)  \
                FROM pg_catalog.pg_locks bl  \
                        JOIN pg_catalog.pg_stat_activity a  \
                                ON bl.pid = a.pid  \
                        JOIN pg_catalog.pg_locks kl  \
                                ON bl.locktype = kl.locktype  \
                                and bl.database is not distinct from kl.database  \
                                and bl.relation is not distinct from kl.relation  \
                                and bl.page is not distinct from kl.page  \
                                and bl.tuple is not distinct from kl.tuple  \
                                and bl.transactionid is not distinct from kl.transactionid  \
                                and bl.classid is not distinct from kl.classid  \
                                and bl.objid is not distinct from kl.objid  \
                                and bl.objsubid is not distinct from kl.objsubid  \
                                and bl.pid <> kl.pid  \
                        JOIN pg_catalog.pg_stat_activity ka  \
                                ON kl.pid = ka.pid  \
                WHERE kl.granted and not bl.granted  \
                        AND ( a.query_start < (now() - interval '"${LOCKTIMEOUT}"') OR ka.query_start < (now() - interval '"${LOCKTIMEOUT}"') )  \
    ;";

CNT=$( psql -h ${HOST} -p ${PORT} -U ${USERNAME} -d ${DBNAME} -Atq -c "${CMD}" );

CMD="WITH cte as (  \
                SELECT 'database'::text as \"database\", 'blocking_AGE'::text as \"blocking_AGE\", 'blocking_pid'::text as blocking_pid, 'blocking_user(Who)'::text as blocking_user, 'blocking_query_start'::text as blocking_query_start, 'blocking_mode'::text as blocking_mode, 'blocking_relation'::text as blocking_relation, 'blocked_AGE'::text as \"blocked_AGE\", 'blocked_pid'::text as blocked_pid, 'blocked_user'::text as blocked_user, 'blocked_query_start'::text as blocked_query_start, 'blocked_mode'::text as blocked_mode, 'blocked_relation'::text as blocked_relation, 'blocking_query'::text as blocking_query, 'blocked_query'::text as blocked_query, 1::text as ord  \
        UNION  \
		SELECT  \
				ka.datname::text as database,  \
				to_char(age(now(), ka.query_start),'HH24h:MIm:SSs')::text as \"blocking_AGE\",  \
				kl.pid::text as blocking_pid,  \
				ka.usename::text as \"blocking_user\",  \
				ka.query_start::text as blocking_query_start,  \
				string_agg(kl.mode, ', ' order by kl.mode)::text as \"blocking_mode\",  \
				ARRAY(SELECT r1.relation FROM pg_catalog.pg_locks r1 WHERE r1.virtualtransaction=kl.virtualtransaction AND r1.relation is not null GROUP BY r1.relation)::text as \"blocking_relation\",  \
				to_char(age(now(), a.query_start),'HH24h:MIm:SSs')::text as \"blocked_AGE\",  \
				bl.pid::text as blocked_pid,  \
				a.usename::text as blocked_user,  \
				a.query_start::text as blocked_query_start,  \
				bl.mode::text as \"blocked_mode\",  \
				ARRAY(SELECT r1.relation FROM pg_catalog.pg_locks r1 WHERE r1.virtualtransaction=bl.virtualtransaction AND r1.relation is not null GROUP BY r1.relation)::text as \"blocked_relation\",  \
				ka.query::text as blocking_query,  \
				a.query::text as blocked_query,  \
				2::text as ord  \
		FROM pg_catalog.pg_locks bl  \
				JOIN pg_catalog.pg_stat_activity a  \
						ON bl.pid = a.pid  \
				JOIN pg_catalog.pg_locks kl  \
						ON bl.locktype = kl.locktype  \
						and bl.database is not distinct from kl.database  \
						and bl.relation is not distinct from kl.relation  \
						and bl.page is not distinct from kl.page  \
						and bl.tuple is not distinct from kl.tuple  \
						and bl.transactionid is not distinct from kl.transactionid  \
						and bl.classid is not distinct from kl.classid  \
						and bl.objid is not distinct from kl.objid  \
						and bl.objsubid is not distinct from kl.objsubid  \
						and bl.pid <> kl.pid  \
				JOIN pg_catalog.pg_stat_activity ka  \
						ON kl.pid = ka.pid  \
		WHERE kl.granted and not bl.granted  \
                        AND ( a.query_start < (now() - interval '"${LOCKTIMEOUT}"') OR ka.query_start < (now() - interval '"${LOCKTIMEOUT}"') )  \
		GROUP BY ka.datname, a.query_start, kl.pid, ka.usename, ka.query_start, \"blocking_relation\", bl.pid, a.usename, a.query_start, bl.mode, \"blocked_relation\", ka.query, a.query  \
        )  \
        SELECT \"database\", \"blocking_AGE\", \"blocking_pid\", \"blocking_user\", \"blocking_query_start\", \"blocking_mode\", \"blocking_relation\", \"blocked_AGE\", \"blocked_pid\", \"blocked_user\", \"blocked_query_start\", \"blocked_mode\", \"blocked_relation\", \"blocking_query\", \"blocked_query\" FROM cte ORDER BY ord, blocked_query_start, blocking_query_start, blocking_pid, blocked_pid, blocking_mode   \
        ;";

MSG=$( psql -h ${HOST} -p ${PORT} -U ${USERNAME} -d ${DBNAME} -Htq -c "${CMD}" 2>/dev/null | sed 's/<table border=\"1\">/<table border=\"1\" style=\"font-family:consolas;font-size:8px\">/' );

MSGLEN=$(echo "${MSG}" | wc -l);

if [[ "${MSGLEN}" -gt "3" ]]
then

MSG=$(echo ${MSG}'<BR>
<p style="font-family:consolas;font-size:10px">
<a href="https://postgrespro.ru/docs/postgresql/10/explicit-locking#TABLE-LOCK-COMPATIBILITY">
Table 13.2. Conflicting Lock Modes
</a></p>
<table border="1" style="font-family:consolas;font-size:9px">
  <tr valign="top">
    <th align="left" style="background-color:#ebebeb">Requested Lock Mode</th>
    <th align="left" style="background-color:#cccccc">ACCESS SHARE</th>
    <th align="left" style="background-color:#cccccc">ROW SHARE</th>
    <th align="left" style="background-color:#cccccc">ROW EXCLUSIVE</th>
    <th align="left" style="background-color:#cccccc">SHARE UPDATE EXCLUSIVE</th>
    <th align="left" style="background-color:#cccccc">SHARE</th>
    <th align="left" style="background-color:#cccccc">SHARE ROW EXCLUSIVE</th>
    <th align="left" style="background-color:#cccccc">EXCLUSIVE</th>
    <th align="left" style="background-color:#cccccc">ACCESS EXCLUSIVE</th>
  </tr>
  <tr valign="top">
    <th align="left" style="background-color:#ebebeb">ACCESS SHARE</th>
    <td align="center"> </td>
    <td align="center"> </td>
    <td align="center"> </td>
    <td align="center"> </td>
    <td align="center"> </td>
    <td align="center"> </td>
    <td align="center"> </td>
    <td align="center">X</td>
  </tr>
  <tr valign="top">
    <th align="left" style="background-color:#ebebeb">ROW SHARE</th>
    <td align="center"> </td>
    <td align="center"> </td>
    <td align="center"> </td>
    <td align="center"> </td>
    <td align="center"> </td>
    <td align="center"> </td>
    <td align="center">X</td>
    <td align="center">X</td>
  </tr>
  <tr valign="top">
    <th align="left" style="background-color:#D1EDB3">ROW EXCLUSIVE</th>
    <td align="center" style="background-color:#D1EDB3"> </td>
    <td align="center" style="background-color:#D1EDB3"> </td>
    <td align="center" style="background-color:#D1EDB3"> </td>
    <td align="center" style="background-color:#D1EDB3"> </td>
    <td align="center" style="background-color:#D1EDB3">X</td>
    <td align="center" style="background-color:#D1EDB3">X</td>
    <td align="center" style="background-color:#D1EDB3">X</td>
    <td align="center" style="background-color:#D1EDB3">X</td>
  </tr>
  <tr valign="top">
    <th align="left" style="background-color:#D1EDB3">SHARE UPDATE EXCLUSIVE</th>
    <td align="center" style="background-color:#D1EDB3"> </td>
    <td align="center" style="background-color:#D1EDB3"> </td>
    <td align="center" style="background-color:#D1EDB3"> </td>
    <td align="center" style="background-color:#D1EDB3">X</td>
    <td align="center" style="background-color:#D1EDB3">X</td>
    <td align="center" style="background-color:#D1EDB3">X</td>
    <td align="center" style="background-color:#D1EDB3">X</td>
    <td align="center" style="background-color:#D1EDB3">X</td>
  </tr>
  <tr valign="top">
    <th align="left" style="background-color:#ebebeb">SHARE</th>
    <td align="center"> </td>
    <td align="center"> </td>
    <td align="center">X</td>
    <td align="center">X</td>
    <td align="center"> </td>
    <td align="center">X</td>
    <td align="center">X</td>
    <td align="center">X</td>
  </tr>
  <tr valign="top">
    <th align="left" style="background-color:#ebebeb">SHARE ROW EXCLUSIVE</th>
    <td align="center"> </td>
    <td align="center"> </td>
    <td align="center">X</td>
    <td align="center">X</td>
    <td align="center">X</td>
    <td align="center">X</td>
    <td align="center">X</td>
    <td align="center">X</td>
  </tr>
  <tr valign="top">
    <th align="left" style="background-color:#D1EDB3">EXCLUSIVE</th>
    <td align="center" style="background-color:#D1EDB3"> </td>
    <td align="center" style="background-color:#D1EDB3">X</td>
    <td align="center" style="background-color:#D1EDB3">X</td>
    <td align="center" style="background-color:#D1EDB3">X</td>
    <td align="center" style="background-color:#D1EDB3">X</td>
    <td align="center" style="background-color:#D1EDB3">X</td>
    <td align="center" style="background-color:#D1EDB3">X</td>
    <td align="center" style="background-color:#D1EDB3">X</td>
  </tr>
  <tr valign="top">
    <th align="left" style="background-color:#D1EDB3">ACCESS EXCLUSIVE</th>
    <td align="center" style="background-color:#D1EDB3">X</td>
    <td align="center" style="background-color:#D1EDB3">X</td>
    <td align="center" style="background-color:#D1EDB3">X</td>
    <td align="center" style="background-color:#D1EDB3">X</td>
    <td align="center" style="background-color:#D1EDB3">X</td>
    <td align="center" style="background-color:#D1EDB3">X</td>
    <td align="center" style="background-color:#D1EDB3">X</td>
    <td align="center" style="background-color:#D1EDB3">X</td>
  </tr>
</table>
');

if [[ "${CNT}" -ne "0" ]]
then

if [[ -v MAILSMTP ]]; then

# MAILSMTP='smtp.inbox.ru:465'
cmdsend=$(echo "mutt -e \"set content_type=text/html\" -e \"set send_charset=utf-8\" -e \"set allow_8bit=yes\" -e \"set use_ipv6=no\" -e \"set move=no\" \
    -e \"set from=\\\"${MAILLOGIN}\\\"\" -e \"set realname=\\\"${MAILFROM}\\\"\" \
    -e \"set smtp_authenticators=\\\"login\\\"\" -e \"set smtp_url=smtps://\\\"${MAILLOGIN}\\\"@\\\"${MAILSMTP}\\\"\" -e \"set smtp_pass=\\\"${MAILPWD}\\\"\" \
    -e \"set ssl_starttls=yes\" -e \"set ssl_force_tls=yes\" -e \"set ssl_verify_dates=no\" -e \"set ssl_verify_host=no\" -s \"PostgreSQL Locks\" ${MAILTO}")
#echo ${cmdsend}

echo ${MSG} | mutt -e "set content_type=text/html" -e "set send_charset=utf-8" -e "set allow_8bit=yes" -e "set use_ipv6=no" -e "set move=no" -e "set copy=no" \
    -e "set from=\"${MAILLOGIN}\"" \
    -e "set realname=\"${MAILFROM}\"" -e "set smtp_authenticators=\"login\"" -e "set smtp_url=smtps://\"${MAILLOGIN}\"@\"${MAILSMTP}\"" -e "set smtp_pass=\"${MAILPWD}\"" \
    -e "set ssl_starttls=yes" -e "set ssl_force_tls=yes" -e "set ssl_verify_dates=no" -e "set ssl_verify_host=no" -s "PostgreSQL Locks" ${MAILTO} 2>&1 | ts '[pg locks]   '
RC=$?
echo "[pg locks]  Send Locks Report. RC=${RC}"

fi

if [[ -v MAILSMTPURL ]]; then

# MAILSMTPURL='smtp://10.42.161.197:25'
cmdsend=$(echo "mutt -e \"set ssl_starttls=no\" -e \"set ssl_force_tls=no\" -e \"set content_type=text/html\" -e \"set send_charset=utf-8\" -e \"set allow_8bit=yes\" \
    -e \"set use_ipv6=no\" -e \"set move=no\" -e \"set from=\\\"${MAILLOGIN}\\\"\" -e \"set realname=\\\"${MAILFROM}\\\"\" -e \"set smtp_url=\\\"${MAILSMTPURL}\\\"\" \
    -s \"PostgreSQL Locks\" ${MAILTO}")
#echo ${cmdsend}

echo ${MSG} | mutt -e "set ssl_starttls=no" -e "set ssl_force_tls=no" -e "set content_type=text/html" -e "set send_charset=utf-8" -e "set allow_8bit=yes" \
    -e "set use_ipv6=no" -e "set move=no" -e "set copy=no" -e "set from=\"${MAILLOGIN}\"" -e "set realname=\"${MAILFROM}\"" -e "set smtp_url=\"${MAILSMTPURL}\"" \
    -s "PostgreSQL Locks" ${MAILTO} 2>&1 | ts '[pg locks]   '
RC=$?
echo "[pg locks]  Send Locks Report. RC=${RC}"

fi

else

echo "[pg locks]  nothing"

fi # CNT

else

echo "[pg locks]  nothing"

fi # MSGLEN
