# Goal

Generate Sqlite relational databases from the JMDICT japanese dictionary.

# setup

## Dart SDK 

SQL is generated using scripts written in `dart`; 

## Dart packages

Download required packages with

	`pub get`

## Utils required binaries

`bash` scripts are in the `src` directory to download dictionaries with `wget` and uncompressed them with `gunzip`.


## Generate .db 

sqlite3 db files are created and populated using the `sqlite3` binary.

```
sudo apt install sqlite3
```

# run.bash

Bash scripts src/run.bash can be called with arguments

    bash src/run.bash <kanji|expression|help> [arguments]
    --download   download JMdict (expression) or kanjidic2 (kanji)
    --sql        generate sql from downloaded dictionary
    --init       create db file tables
    --populate   populate db file from generated sql
    --clean     delete db and sql file


# Generate expression sql for selected languages

The `src/expression/create_sql.dart` script can be called with arguments to process only some languages.

The languages are in ISO 639-3 format, for example: 

English and French

```
dart src/expression/create_sql.dart eng fre
```

English only

```
dart src/expression/create_sql.dart eng
```

All languages

```
dart src/expression/create_sql.dart
```

note: `run.bash --sql` does not allow to pass language arguments. 

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
