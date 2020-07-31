#!/bin/bash



CURDIR=$(pwd)

DATESTR=$(date +"%Y-%m-%d")

if [ "${#}" -lt 1 ] || ! [ -d "${1}" ]; then
    echo "Usage: ${0} INPUT_DIR [OUTPUT_PREFIX]" >&2
    exit 1
fi


TARGET_BASE=$(basename "${1}")
TARGET_DIR=$(dirname "${1}")
TARGET_PATH="${TARGET_DIR}/${TARGET_BASE}"
OUTPUT_PREFIX="${TARGET_BASE}"

if [ "${#}" -gt 1 ]; then
    OUTPUT_PREFIX=${2}
fi

OUTPUT_FILE="${OUTPUT_PREFIX}.${DATESTR}.tar.gz"

#echo "TARGET_BASE=${TARGET_BASE}"
#echo "TARGET_DIR=${TARGET_DIR}"
#echo "TARGET_PATH=${TARGET_PATH}"


cd ${TARGET_DIR}

echo "Compressing ${TARGET_PATH} to ${OUTPUT_FILE}"

#tar czfP ${TARGET_BASE}.tar.gz ${TARGET_DIR}

## [Progress Monitoring]
## reference: [https://superuser.com/questions/168749/is-there-a-way-to-see-any-tar-progress-per-file]

## 1. dash '-' means send result to STDOUT, which can be passed through the pipe. reference: [https://stackoverflow.com/questions/24079926/tar-command-what-is-dash-for]
## 2. 'tar z' uses gzip. Without a 'z', gzip is required at the end.
## 3. 'pv' is a tool for process monitoring.
tar cfP - ${TARGET_BASE} \
    | pv -s $( du -sb ${TARGET_BASE} | awk '{print $1}' ) \
    | gzip > ${CURDIR}/${OUTPUT_FILE}



cd ${CURDIR}
