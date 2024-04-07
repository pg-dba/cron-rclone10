#!/bin/bash
# c_analyze.sh

logfile="/cronwork/ANALYZE.log";

IFS="|";
echo "===== ${HOST} ANALYZE started ====="  2>&1;
echo "===== $(date --iso-8601=seconds) ANALYZE started ====="  > ${logfile} 2>&1;
cmd1="SELECT datname FROM pg_database WHERE datistemplate = false;";
DBs=($(PGPASSWORD=${PASSWORD} psql -h ${HOST} -p ${PORT} -U ${USERNAME} -d postgres -c "${cmd1}" -XAt | tr -s '\n' '|' | tr -d '\r'));
for dbName in ${!DBs[*]}; do
cmd5="SELECT '===== ' || to_char(now() , 'YYYY-MM-DD\"T\"HH24:MI:SSOF') || ':00' || ' ===== ' || current_database() || ' ===== ' || (SELECT count(*) FROM pg_available_extensions WHERE installed_version is not null AND installed_version <> default_version)::text || ' ' || ARRAY(SELECT x.extname FROM pg_extension x JOIN pg_namespace n ON n.oid = x.extnamespace ORDER BY x.extname)::text || ' =====';";
PGPASSWORD=${PASSWORD} psql -h ${HOST} -p ${PORT} -U ${USERNAME} -d ${DBs[$dbName]} -c "${cmd5}" -XAt >> ${logfile} 2>&1;
cmd2="select table_schema from information_schema.tables where table_schema not in ('pg_catalog','information_schema') group by 1;";
Ss=($(PGPASSWORD=${PASSWORD} psql -h ${HOST} -p ${PORT} -U ${USERNAME} -d ${DBs[$dbName]} -c "${cmd2}" -XAt | tr -s '\n' '|' | tr -d '\r'));
for sName in ${!Ss[*]}; do
cmd3="select ist.table_name from information_schema.tables as ist left outer join ( SELECT nmsp_parent.nspname::text AS parent_schema, parent.relname::text AS parent  FROM pg_inherits JOIN pg_class parent ON pg_inherits.inhparent = parent.oid JOIN pg_namespace nmsp_parent ON nmsp_parent.oid = parent.relnamespace GROUP BY 1,2 ) pt on pt.parent_schema = ist.table_schema and pt.parent = ist.table_name where ist.table_schema = '${Ss[$sName]}' and pt.parent is null and ist.table_type not ilike 'VIEW%' and ist.table_type not ilike 'FOREIGN%' and ist.table_schema not in ('pg_catalog','information_schema') group by 1 order by 1;";
Ts=($(PGPASSWORD=${PASSWORD} psql -h ${HOST} -p ${PORT} -U ${USERNAME} -d ${DBs[$dbName]} -c "${cmd3}" -XAt | tr -s '\n' '|' | tr -d '\r'));
for tName in ${!Ts[*]}; do
schemaName=$(echo ${Ss[$sName]} | sed 's/"//g');
tableName=$(echo ${Ts[$tName]} | sed 's/"//g');
echo "  $(date --iso-8601=seconds) : ANALYZE VERBOSE \"${schemaName}\".\"${tableName}\";" >> ${logfile} 2>&1;
PGPASSWORD=${PASSWORD} psql -h ${HOST} -p ${PORT} -U ${USERNAME} -d ${DBs[$dbName]} -c "ANALYZE VERBOSE \"${schemaName}\".\"${tableName}\";" >> ${logfile} 2>&1;
done;
done;
done;
echo "===== $(date --iso-8601=seconds) ANALYZE finished =====" 2>&1 1>>${logfile};
echo "===== ${HOST} ANALYZE finished =====" 2>&1;
