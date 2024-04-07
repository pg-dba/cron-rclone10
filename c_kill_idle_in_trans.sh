#!/bin/bash
# c_kill_idle_in_trans.sh

if [[ ("$#" -eq 0) ]]; then
KILLTIMEOUT='30 minutes';
else
KILLTIMEOUT="$1";
fi
premsg='kill idle in trans';

PGPASSWORD=${PASSWORD} psql -h ${HOST} -p ${PORT} -U ${USERNAME} -d ${DBNAME} -At -c " \
	INSERT INTO public.log_kills( \
		kill ,killer ,typekill ,ok \
		,datid ,datname ,pid ,usesysid ,usename ,application_name ,client_addr ,client_hostname ,client_port \
		,backend_start ,xact_start ,query_start ,state_change ,wait_event_type ,wait_event ,state ,backend_xid ,backend_xmin ,backend_type ,query) \
	SELECT clock_timestamp() as kill \
		,session_user as killer \
		,'terminate' as typekill \
		,pg_terminate_backend(pid) as ok \
		,datid ,datname ,pid ,usesysid ,usename ,application_name ,client_addr ,client_hostname ,client_port \
		,backend_start ,xact_start ,query_start ,state_change ,wait_event_type ,wait_event ,state ,backend_xid ,backend_xmin ,backend_type ,query \
	FROM pg_catalog.pg_stat_activity \
	WHERE state in ('idle in transaction', 'idle in transaction (aborted)') \
	AND current_timestamp - state_change > interval '${KILLTIMEOUT}' \
	/* AND usename <> 'postgres' А ЗДЕСЬ ПРИДЁТСЯ ИЗВРАЩАТЬСЯ, если всё от имени postgres */ \
	AND usename <> 'barman' \
	AND usename <> 'streaming_barman' \
	AND backend_type = 'client backend' /* м.б. это подойдёт */ \
	AND pid <> pg_backend_pid() \
        ;" 2>&1 | ts "[${premsg}] " ;
