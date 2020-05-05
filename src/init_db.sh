#!/usr/bin/env bash

source src/_check_args.sh $1

db=$1
db_path="data/generated/db/${db}.db"
sql_init_path="data/init/${db}.sql"

if [ ! -f $db_path ]; then
    sqlite3 $db_path < $sql_init_path
    echo "created ${db_path} from ${sql_init_path}"
else
    echo "${db_path} alderly exists."
fi
