#!/usr/bin/env bash

wget http://ftp.monash.edu/pub/nihongo/JMdict.gz --directory-prefix=data
gunzip data/JMdict.gz
