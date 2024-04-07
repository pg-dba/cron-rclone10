#!/bin/bash

PGPASSWORD=${PASSWORD} psql -h ${HOST} -p ${PORT} -U ${USERNAME} -d ${DBNAME} -xtA -c "SELECT profile.take_sample();" 2>&1 | sed -n '1p' | ts '[pg_profile] ';
