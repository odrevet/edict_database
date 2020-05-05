# setup

SQL is generated using scripts written in `dart`.

Download required packages with

	pub get


`bash` scripts are in the `src` directory to download dictionaries with `wget` and uncompressed them with `gunzip`.

sqlite db files are created and populated using the `sqlite3` binary.

# src scripts

.sh files are executed with bash
.dart files are executed with dart

# Call location

Scripts needs to be called from the projet's root

# Steps to create db files

## 1. Get Dictionaries

    bash src/expression/get_jmdict.sh
    bash src/kanji/get_kanjidic2.sh

Please note that for some reason the doctype (from <!DOCTYPE kanjidic2 [ to ]> )of kanjidic2.xml cannot be parsed to generate SQL and must be remove before calling create_sql.sh.

## 2. Init db

To create the data/generated/db/expression.db file

    bash src/init_db.sh expression

To create the data/generated/db/kanji.db file

	bash src/init_db.sh kanji

## 3. Create sql

To create the data/generated/sql/expression.sql file

	bash src/create_sql.sh expression

To create the data/generated/sql/kanji.sql file

	bash src/create_sql.sh kanji

## 4. Populate db from generated sql files


To populate the data/generated/db/expression.db file

	bash src/populate_db.sh expression

To populate the data/generated/db/kanji.db file

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

For more informations onto the database structure see the database.md file.

# Licencing

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
