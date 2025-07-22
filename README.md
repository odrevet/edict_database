# Goal

Generate Sqlite relational databases from the JMDICT japanese dictionary.

# setup

## Dart SDK 

SQL is generated using scripts written in `dart`; 

## Dart packages

Download required packages with

`dart pub get`

## Utils required binaries

`bash` scripts are in the `src` directory to download dictionaries with `wget` and uncompressed them with `gunzip`.


## Generate .db 

sqlite3 db files are created and populated using the `sqlite3` binary.

```
sudo apt install sqlite3
```

# run.bash

Bash scripts `src/run.bash` can be called with arguments

    bash run.bash <kanji|expression|help> [arguments]
    arguments:
    --download         download JMdict (expression) or kanjidic2 (kanji)
    --sql [languages]  generate sql from downloaded dictionary.
    --init             create db file tables
    --populate         populate db file from generated sql
    --clean [what]     delete db and/or sql file



Example: Reset previously generated expression database, generate sql for english sense and populate the db: 

```
bash src/run.bash expression --clean --init --sql "eng" --populate
```

```
bash src/run.bash kanji --clean --init --sql "en" --populate
```

# Generate sql for selected languages

The `src/create_sql_expression.dart` and `src/create_sql_kanji.dart` scripts can be called with arguments to process only some languages.

The languages are in ISO 639-3 format for expression and ISO 639-2 for kanji, for example: 

English and French

```
dart src/create_sql_expression.dart eng fre
```

English only

```
dart src/create_sql_expression.dart eng
```

```
dart src/create_sql_kanji.dart en
```

note: `run.bash`  allow to pass language arguments with quotes, for example: 

```
bash src/run.bash expression --sql "eng fre"
```

# Documentation

For more informations onto the database structure and SQL reicips see the Wiki at https://github.com/odrevet/edict_database/wiki

# Licencing

The edict_database project is not affiliated with the edict project. 

The source code in the src folder is licenced under the MIT license

The generated sql and db files are licenced under the edrdg license, same as the edict dictionary.

# Links

http://www.edrdg.org/

## Radkfile

* http://www.edrdg.org/krad/kradinf.html

## JMdict

* https://www.edrdg.org/jmdict/jmdictart.html
* http://www.edrdg.org/jmdict/edict_doc.html
* http://ftp.monash.edu/pub/nihongo/JMdict.gz

## kanjidict

* http://www.edrdg.org/wiki/index.php/KANJIDIC_Project
* http://nihongo.monash.edu/kanjidic2/kanjidic2.xml.gz
