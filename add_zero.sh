#!/bin/bash

find -maxdepth 1 -type d -regextype egrep -regex './[0-9]{3}[-_.a-zA-Z0-9]*' -exec bash -c 'FILENAME=`echo "{}"|cut -d"/" -f2`; mv ./${FILENAME} ./0${FILENAME}' \;

