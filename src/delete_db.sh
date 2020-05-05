#!/usr/bin/env bash

source src/_check_args.sh $1

db=$1
db_path="data/generated/db/${db}.db"

rm -f $db_path
echo "deleted ${db_path}"
