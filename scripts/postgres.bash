#!/usr/bin/env bash

usage() {
  echo "bash run.bash <kanji|expression|help> [arguments]"
  echo "arguments: "
  echo "--init               create db tables"
  echo "--populate           populate db file from generated sql"
  echo "--clean              wipe database"
  echo "--psql-args <args>   extra arguments passed to psql (e.g. service=edict)"
}

subject=$1

if [ "$subject" = "help" ]; then
  usage
  exit
fi

if [ "$subject" != "kanji" ] && [ "$subject" != "expression" ]; then
  echo "First parameter must be 'kanji' or 'expression'"
  usage
  exit
fi

while true; do
  action=$2
  echo $action
  case "$2" in
  --init)
    psql $PSQL_ARGS -U postgres -d edict < data/init/postgres/${subject}.sql
    shift
    ;;
  --populate)
    psql $PSQL_ARGS -U postgres -d edict < data/init/postgres/copy_${subject}.sql
    shift
    ;;
  --clean)
    psql $PSQL_ARGS -U postgres -d edict -c "DROP SCHEMA ${subject} CASCADE; CREATE SCHEMA ${subject};"
    shift
    ;;
  --psql-args)
    PSQL_ARGS=$3
    shift 2
    ;;
  *) break ;;
  esac
done