#!/usr/bin/env bash

usage() {
  echo "bash run.bash <kanji|expression|help> [arguments]"
  echo "arguments: "
  echo "--download         download JMdict (expression) or kanjidic2 (kanji)"
  echo "--sql [languages]  generate sql from downloaded dictionary."
  echo "--init             create db file tables"
  echo "--populate         populate db file from generated sql"
  echo "--compress         create a zip archive of the database file"
  echo "--clean [what]     delete db and/or sql file"
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
  --sql)
    shift

    languages=""
    if [[ $2 != --* ]]; then
      languages=$2
      shift
    fi

    dart "src/create_sql_${subject}.dart" $languages

    ;;
  --init)
    db_path="data/generated/db/${subject}.db"
    sql_init_path="data/init/${subject}.sql"

    if [ ! -f $db_path ]; then
      sqlite3 $db_path <$sql_init_path
      echo "created ${db_path} from ${sql_init_path}"
    else
      echo "${db_path} already exists."
    fi
    shift
    ;;
  --populate)
    db_path="data/generated/db/${subject}.db"
    sql_generated_path="data/generated/sql/${subject}.sql"

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
    if [ "$subject" = "expression" ]; then
      wget ftp://ftp.edrdg.org/pub/Nihongo/JMdict.gz --directory-prefix=data
      gunzip data/JMdict.gz
    else
      wget http://www.edrdg.org/kanjidic/kanjidic2.xml.gz --directory-prefix=data
      gunzip data/kanjidic2.xml.gz
    fi
    shift
    ;;
  --compress)
    db_path="data/generated/db/${subject}.db"
    db_dir=$(dirname "$db_path")
    db_filename=$(basename "$db_path")
    zip_path="${db_dir}/${subject}.zip"

    if [ ! -f $db_path ]; then
      echo "Database file ${db_path} not found. Cannot compress."
      exit 1
    fi

    echo "Compressing ${db_path} to ${zip_path}..."
    cd "$db_dir"
    zip "${subject}.zip" "$db_filename"
    cd - > /dev/null
    echo "Created compressed archive: ${zip_path}"
    shift
    ;;
  --clean)
    shift
    what=""
    if [[ $2 != --* ]]; then
      what=$2
      shift
    fi

    if [ "$what" = "sql" ] || [ "$what" = "" ]; then
      rm "data/generated/sql/${subject}.sql"
    fi

    if [ "$what" = "db" ] || [ "$what" = "" ]; then
      rm "data/generated/db/${subject}.db"
    fi
    ;;
  *) break ;;
  esac
done