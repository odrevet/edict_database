#!/usr/bin/env bash

source src/_check_args.sh $1

db=$1
db_path="data/generated/db/${db}.db"
sql_generated_path="data/generated/sql/${db}.sql"

if [ ! -f $sql_generated_path ]; then
    echo "file ${sql_generated_path} not found. Please run 'bash src/create_sql.sh ${db}'"
    exit
fi

if [ -f $db_path ]; then
    echo "Populating ${db_path}..."
    echo "PRAGMA synchronous=OFF;PRAGMA journal_mode=OFF;PRAGMA temp_store=MEMORY;" | cat - $sql_generated_path | sqlite3 $db_path
else
    echo "file ${db_path} do not exists. Please run 'bash src/init_db.sh ${db}'"
fi
