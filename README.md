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

Bash scripts are provided in order to facilitate the creation of .db files.

Scripts needs to be called from the projet's root

# Steps to create db files

## 1. Get Dictionaries

    bash src/expression/get_jmdict.sh
    bash src/kanji/get_kanjidic2.sh

Will download dictionary files into the `data` directory. 

Please note that for some reason the doctype (from <!DOCTYPE kanjidic2 [ to ]> )of kanjidic2.xml cannot be parsed to generate SQL and must be remove before calling create_sql.sh.

## 2. Create sql

To create the `data/generated/sql/expression.sql` file

	bash src/create_sql.sh expression

To create the data/generated/sql/kanji.sql file

	bash src/create_sql.sh kanji

## 3. Init db

Create .db file  

To create the `data/generated/db/expression.db` file

    bash src/init_db.sh expression

To create the `data/generated/db/kanji.db` file

	bash src/init_db.sh kanji

## 4. Populate db from generated sql files


To populate the `data/generated/db/expression.db` file

	bash src/populate_db.sh expression

To populate the `data/generated/db/kanji.db` file

	bash src/populate_db.sh kanji


## Other scripts

* delete_sql.sh

Remove the expression or kanji generated sql.

Needs to be called between calls to create_sql.sh as the sql in append to the sql file.

* delete_db.sh

Delete the expression or kanji database

* reset_db.sh

call delete_db.sh then init_db.sh

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
