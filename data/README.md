This directory contains data (.xml, .sql, .db)

# JMDict and kanjidict2.xml files

JMDict and kanjidict2.xml files are respectivly the JMDict dictionary and the kanjidict2 dictionary in there xml format.

This is from these two file that we will generate the sql and db files.

They are not shipped by default with our project, instead we will use the `src/expression/get_jmdict.sh` and `src/kanji/ get_kanjidic2.sh` scripts to download and decompress these files.

# radkfile.json file

Needed to build the sql for kanji.db, this file has been created by hand from RADKFILE (not included in this project)

This file contains the same data as RADKFILE but formated as json.

# init

Contains the sql instructions to create the database structure

# generated

## sql

contains the sql with insert statments generated from JMDict and kanjidict2.xml files

This directory is empty by default, generated sql files are shipped separatly with each release

## db

contains generated sqlite db file from sql files

.db file are initialized with there hierarchical structure with file in the init directory, they are then populated with the data from generated/sql

This directory is empty by default, generated db files are shipped separatly with each release
