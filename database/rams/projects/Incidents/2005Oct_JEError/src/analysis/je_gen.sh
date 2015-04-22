#!/bin/sh

set -x

DB_HOST=facqa
record_je_adj=./je_adj.sql
file_one=je_one.txt
file_two=je_two.txt

sqlplus -s /@${DB_HOST} @${record_je_adj} $file_one $file_two
