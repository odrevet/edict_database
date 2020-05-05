#!/usr/bin/env bash

source src/_check_args.sh $1

db=$1

dart "src/${db}/create_sql.dart"
