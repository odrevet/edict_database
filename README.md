# Goal

Generate Sqlite relational databases from the JMDICT japanese dictionary.

# setup

## Dart SDK 

SQL is generated using scripts written in `dart`; 

## Dart packages

Download required packages with

	pub get

## Utils required binaries

`bash` scripts are in the `src` directory to download dictionaries with `wget` and uncompressed them with `gunzip`.


## Generate .db 

sqlite3 db files are created and populated using the `sqlite3` binary.

```
sudo apt install sqlite3
```

# scripts

Bash scripts src/run.bash can be called with arguments

# Steps to create db files

## 1. Get Dictionaries

    bash src/run.bash kanji --download
    bash src/run.bash expression --download

Will download dictionary files into the `data` directory.

## 2. Create sql

To create the `data/generated/sql/expression.sql` file

	bash src/run.bash expression sql

To create the `data/generated/sql/kanji.sql` file

	bash src/run.bash kanji sql

## 3. Init db

Create .db file

To create the `data/generated/db/expression.db` file

    bash src/run.bash expression --init

To create the `data/generated/db/kanji.db` file

	bash src/run.bash kanji --init

## 4. Populate db from generated sql files

To populate the `data/generated/db/expression.db` file

	bash src/run.bash expression --populate

To populate the `data/generated/db/kanji.db` file

	bash src/run.bash kanji --populate


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
