# Goal

Generate SQLite and PostgreSQL relational databases from Japanese dictionary data sources:

- **JMdict**: Japanese-multilingual dictionary data (expression/vocabulary entries)
- **KANJIDIC2**: Comprehensive kanji character information
- **RADKFILE**: Kanji radical decomposition data

The tool produces SQL schemas for SQLite, as well as CSV exports, used by PostgreSQL.

# setup

## Dart SDK 

SQL is generated using scripts written in `dart`; 

## Dart packages

Download required packages with

`dart pub get`


# Generate sql for selected languages

`SQL` or `CSV` are generated using `dart` under the `src` directory.

* to SQL scripts

The `src/to_sql_expression.dart` and `src/to_sql_kanji.dart`

Options : 

* --langs languages to process (gloss or meanings), comma separated list The languages are in ISO 639-3 format for expression and ISO 639-2 for kanji
* --max-inserts How many VALUES per INSERT in the generated SQL. 0 for all VALUES. 

English and French

```bash
dart src/to_sql_expression.dart --langs "eng,fre" --max-inserts 1
```

English only

```bash
dart src/to_sql_expression.dart --langs "eng"
```

```bash
dart src/to_sql_kanji.dart en
```

The `src/to_sql_expression.dart` and `src/to_sql_kanji.dart`

* to CSV scripts

# generated files

Files are generated under `data/generated` directory

Databases can be opened/tested with `sqlite3` binary

```bash
sqlite3 data/generated/db/expression.db
```

```bash
sqlite3 data/generated/db/kanji.db
```

# Helper scripts

Instead of calling dart directly, helper bash scripts under the `scripts` directory can be used. 

Bash scripts under `scripts` that helps download files, init, populate the databases

For all the scripts the first argument musy be `expression` or `kanji`. 

## scripts/run.sh

* download dictionaries with `wget` and uncompressed them with `gunzip`.

* `--download`: Download JMdict and KANJIDIC2/RADKFILE source files
* `--clean`: Clear generated SQL or CSV files
* `--sql`: Generate SQL insert statements
* `--csv`: Generate CSV files

## scripts/sqlite.sh

sqlite3 db files are created and populated using the `sqlite3` binary.

```bash
sudo apt install sqlite3
```

* `--init`: Create SQLite database file with tables and indexes
* `--populate`: Insert data using previously generated SQL
* `--compress`: Compress the SQLite database
* `--clean`: Remove the database

## scripts/postgres.sh


Postgres database is populated using `psql`.

* `--init`: Create PostgreSQL database with tables and indexes
* `--populate`: Import data using previously generated CSV files via COPY
* `--clean`: Remove the database

## Helper scripts examples 

First download the dictionaries

```
bash scripts/run.bash expression --download
bash scripts/run.bash kanji --download
```

### sqlite 

generate sql for english sense and populate the db and compress:

* For expression

```bash
bash scripts/run.bash expression --sql "eng"
bash scripts/sqlite.bash expression --clean --init --populate --compress "zip" --compress "xz"
```

* For kanji

```bash
bash scripts/run.bash kanji --clean --init --sql "en"
bash scripts/sqlite.bash kanji --populate --compress "zip" --compress "xz"
```

### postgres using docker

* Create a container

```
docker run -v "$(pwd):/workspace" \
  --name postgres-container \
  -e POSTGRES_PASSWORD=mysecretpassword \
  -e POSTGRES_DB=edict \
  -p 5432:5432 \
  -d postgres
```

* At next boot

```
docker start postgres-container
```

* Data are imported from csv

```
bash scripts/run.bash expression --csv
bash scripts/run.bash kanji --csv
```

* import expression and kanji

```
docker exec -i -w /workspace postgres-container bash scripts/postgres.bash expression --init --populate
docker exec -i -w /workspace postgres-container bash scripts/postgres.bash kanji --init --populate
```

* Wipe database (expression or kanji option does not matters)

```
docker exec -i -w /workspace postgres-container bash scripts/postgres.bash expression --clean
```

* Interactive session

```
docker exec -it -w /workspace postgres-container psql -U postgres -d edict
```

# Documentation

For more information onto the database structure and SQL recipes see the Wiki at https://github.com/odrevet/edict_database/wiki

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
