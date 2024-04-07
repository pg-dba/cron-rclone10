#!/bin/bash
# c_pg_version.sh
PGPASSWORD=${PASSWORD} PGOPTIONS="-c geqo=off -c statement_timeout=5min -c client_min_messages=error" psql -h ${HOST} -p ${PORT} -U ${USERNAME} -d ${DBNAME} -xtA -c "SELECT LEFT(setting,5)::text as version FROM pg_settings where name='server_version';" 2>&1 | sed -n '1p' | ts '[PostgreSQL] ';
