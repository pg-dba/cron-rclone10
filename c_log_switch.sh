#!/bin/bash
# c_log_switch.sh
PGPASSWORD=${PASSWORD} PGOPTIONS="-c geqo=off -c statement_timeout=5min -c client_min_messages=error" psql -h ${HOST} -p ${PORT} -U ${USERNAME} -d ${DBNAME} -xtA -c "select public.log_switch()::text;" 2>&1 | sed -n '1p' | ts '[pglog] ';
