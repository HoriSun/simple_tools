#!/bin/bash
# reference: [https://unix.stackexchange.com/questions/254463/what-does-the-option-9-mean-for-killall]

# reference: [https://en.wikipedia.org/wiki/Job_control_(Unix)#Implementation]

# reference: [https://en.wikipedia.org/wiki/Signal_(IPC)]

if [ "${#}" -gt 0 ]; then
    killall -s SIGCONT "${@}"
fi
