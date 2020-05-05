#!/usr/bin/env bash

wget http://nihongo.monash.edu/kanjidic2/kanjidic2.xml.gz --directory-prefix=data
gunzip data/kanjidic2.xml.gz
