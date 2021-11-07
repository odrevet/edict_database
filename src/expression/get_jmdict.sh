#!/usr/bin/env bash

wget ftp://ftp.edrdg.org/pub/Nihongo//JMdict.gz --directory-prefix=data
gunzip data/JMdict.gz
