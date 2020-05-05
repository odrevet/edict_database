#!/usr/bin/env bash

source src/_check_args.sh $1

db=$1
sql_path="data/generated/sql/${db}.sql"

rm -f $sql_path
echo "deleted ${sql_path}"
