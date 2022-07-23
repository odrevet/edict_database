#!/usr/bin/env bash

usage() {
  echo "bash run.bash <kanji|expression|help> [arguments]"
  echo "--download   download JMdict (expression) or kanjidic2 (kanji)"
  echo "--sql        generate sql from downloaded dictionary"
  echo "--init       create db file tables"
  echo "--populate   populate db file from generated sql"
  echo "--clean     delete db and sql file"
}

db=$1

if [ "$db" = "help" ]; then
  usage
  exit
fi

if [ "$db" != "kanji" ] && [ "$db" != "expression" ]; then
  echo "First parameter must be 'kanji' or 'expression'"
  usage
  exit
fi

while true; do
  action=$2
  echo $action
  case "$2" in
  --sql)
    shift

    args=""
    if [[ $2 != "--*" ]]; then
      args=$2
      shift
    fi

    dart "src/${db}/create_sql.dart" $args

    ;;
  --init)
    db_path="data/generated/db/${db}.db"
    sql_init_path="data/init/${db}.sql"

    if [ ! -f $db_path ]; then
      sqlite3 $db_path <$sql_init_path
      echo "created ${db_path} from ${sql_init_path}"
    else
      echo "${db_path} alderly exists."
    fi
    shift
    ;;
  --populate)
    db_path="data/generated/db/${db}.db"
    sql_generated_path="data/generated/sql/${db}.sql"

    if [ ! -f $sql_generated_path ]; then
      echo "file ${sql_generated_path} not found."
      exit
    fi

    if [ -f $db_path ]; then
      echo "Populating ${db_path}..."
      echo "PRAGMA synchronous=OFF;PRAGMA journal_mode=OFF;PRAGMA temp_store=MEMORY;" | cat - $sql_generated_path | sqlite3 $db_path
    else
      echo "file ${db_path} not found. "
    fi
    shift
    ;;
  --download)
    if [ "$db" = "expression"]; then
      wget ftp://ftp.edrdg.org/pub/Nihongo//JMdict.gz --directory-prefix=data
      gunzip data/JMdict.gz
    else
      wget http://nihongo.monash.edu/kanjidic2/kanjidic2.xml.gz --directory-prefix=data
      gunzip data/kanjidic2.xml.gz
    fi
    shift
    ;;
  --clean)
    shift
    what=""
    if [[ $2 != "--*" ]]; then
      what=$2
      shift
    fi

    if [ "$what" = "sql" ] || [ "$what" = "" ]; then
      rm "data/generated/sql/${db}.db"
    fi

    if [ "$what" = "db" ] || [ "$what" = "" ]; then
      rm "data/generated/db/${db}.sql"
    fi
    ;;
  *) break ;;
  esac
done
