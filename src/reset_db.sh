#!/usr/bin/env bash
source src/_check_args.sh $1

db=$1
bash "src/delete_db.sh" $db
bash "src/init_db.sh" $db
