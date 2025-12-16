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

```bash
sudo apt install sqlite3
```

# run.bash

Bash scripts under `scripts` that helps download files, init, populate the databases

```
arguments:
--download                    download JMdict (expression) or kanjidic2 (kanji)
--sql [languages] [maxInsert] generate sql from downloaded dictionary.
--csv [languages]             generate sql from downloaded dictionary.
```

Example: Reset previously generated expression database, generate sql for english sense and populate the db and compress: 

* For expression

```bash
bash scripts/run.bash expression --clean --init --sql "eng"
bash scripts/sqlite.bash expression --populate --compress "zip" --compress "xz"
```

* For kanji

```bash
bash scripts/run.bash kanji --clean --init --sql "en"
bash scripts/sqlite.bash kanji --populate --compress "zip" --compress "xz"
```

# Generate sql for selected languages

The `src/to_sql_expression.dart` and `src/to_sql_kanji.dart` scripts can be called with arguments to process only some languages.

The languages are in ISO 639-3 format for expression and ISO 639-2 for kanji, for example: 

English and French

```bash
dart src/to_sql_expression.dart eng fre
```

English only

```bash
dart src/to_sql_expression.dart eng
```

```
dart src/to_sql_kanji.dart en
```

note: `run.bash`  allow to pass language arguments with quotes, for example: 

```bash
bash scripts/run.bash expression --sql "eng,fre"
```

# generated files

Files are generated under `data/generated` directory

Databases can be opened/tested with `sqlite3` binary

```bash
sqlite3 data/generated/db/expression.db
```

```bash
sqlite3 data/generated/db/kanji.db
```

# postgres using docker

* Download the image and create a container

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
