#!/usr/bin/env bash

usage() {
  echo "bash run.bash <kanji|expression|help> [arguments]"
  echo "arguments: "
  echo "--download                    download JMdict (expression) or kanjidic2 (kanji)"
  echo "--sql [languages][maxinsert]  generate sql from downloaded dictionary."
  echo "--csv [languages]             generate csv from downloaded dictionary."
  echo "--clean                       remove generated sql file"
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
    if [ "$subject" == "expression" ]; then
        languages="eng"
    else
        languages="en"
    fi

  if [[ -n "$2" && $2 != --* ]]; then
    languages=$2
    shift
  fi

    maxValuesPerInsert="1"
    if [[ -n "$2" && $2 != --* ]]; then
      maxValuesPerInsert=$2
      shift
    fi

    dart "src/to_sql_${subject}.dart" --langs $languages --max-inserts $maxValuesPerInsert

    ;;
  --csv)
    shift

    languages=""
    if [ "$subject" == "expression" ]; then
        languages="eng"
    else
        languages="en"
    fi

    if [[ -n "$2" && $2 != --* ]]; then
      languages=$2
      shift
    fi

    dart "src/to_csv_${subject}.dart" --langs $languages

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
  --clean)
    shift
    rm -f "data/generated/sql/${subject}.sql"
    ;;
  *) break ;;
  esac
done