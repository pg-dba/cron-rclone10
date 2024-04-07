#!/bin/bash
# c_log_count.sh
PGPASSWORD=${PASSWORD} PGOPTIONS="-c geqo=off -c statement_timeout=5min -c client_min_messages=error" psql -h ${HOST} -p ${PORT} -U ${USERNAME} -d ${DBNAME} -xtA -c "WITH pgl AS (SELECT datacheck, dtright, dtlast FROM public.log_state()) SELECT (SELECT count(*)::text FROM pgl) as log_count,(SELECT count(*)::text FROM pgl WHERE datacheck=false AND dtlast >= (dtright + interval '1 sec')) as bad_log_count;" 2>&1 | ts '[pglog] ';
