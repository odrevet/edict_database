#!/usr/bin/env bash

usage() {
  echo "bash run.bash <kanji|expression|help> [arguments]"
  echo "arguments: "
  echo "--init               create db file tables"
  echo "--populate           populate db file from generated sql"
  echo "--compress [zip|xz]  create a compressed archive of the database file"
  echo "--clean              wipe databases"
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
    db_path="data/generated/db/${subject}.db"
    sql_init_path="data/init/sqlite/${subject}.sql"

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

      {
        echo "PRAGMA synchronous=OFF;"
        echo "PRAGMA journal_mode=OFF;"
        echo "PRAGMA temp_store=MEMORY;"
        echo "PRAGMA cache_size=10000;"
        echo "BEGIN TRANSACTION;"
        cat $sql_generated_path
        echo "COMMIT;"
        echo "ANALYZE;"
      } | sqlite3 $db_path
    else
      echo "file ${db_path} not found. "
    fi
    shift
    ;;
  --compress)
    shift
    format="zip"

    # Check if next argument is a compression format
    if [[ $2 == "zip" ]] || [[ $2 == "xz" ]]; then
      format=$2
      shift
    fi

    db_path="data/generated/db/${subject}.db"
    db_dir=$(dirname "$db_path")
    db_filename=$(basename "$db_path")

    if [ ! -f $db_path ]; then
      echo "Database file ${db_path} not found. Cannot compress."
      exit 1
    fi

    if [ "$format" = "zip" ]; then
      # Check if zip is available
      if ! command -v zip &> /dev/null; then
        echo "Error: zip command not found. Please install zip or use xz format."
        exit 1
      fi

      archive_path="${db_dir}/${subject}.zip"
      echo "Compressing ${db_path} to ${archive_path}..."
      zip -j "${archive_path}" "$db_path"
      echo "Created compressed archive: ${archive_path}"

    elif [ "$format" = "xz" ]; then
      # Check if xz is available
      if ! command -v xz &> /dev/null; then
        echo "Error: xz command not found. Please install xz-utils or use zip format."
        exit 1
      fi

      archive_path="${db_dir}/${subject}.xz"
      echo "Compressing ${db_path} to ${archive_path}..."
      # Use -c to write to stdout, redirect to archive file
      xz -9 -c "$db_path" > "${archive_path}"
      echo "Created compressed archive: ${archive_path}"

    else
      echo "Unknown compression format: ${format}"
      echo "Supported formats: zip, xz"
      exit 1
    fi
    ;;
  --clean)
    rm -f "data/generated/db/${subject}.db"
    rm -f "data/generated/db/${subject}.zip"
    rm -f "data/generated/db/${subject}.xz"
    shift
    ;;
  *) break ;;
  esac
done