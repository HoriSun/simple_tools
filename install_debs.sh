#!/bin/bash

ORI_DIR=`pwd`

cd ${HOME}

CACHE_DIR="${HOME}/cache"
DEB_DIR="${HOME}/install/deb"



PRINT_GREY="\033[30m"
PRINT_RED="\033[31m"
PRINT_GREEN="\033[32m"
PRINT_YELLOW="\033[33m"
PRINT_BLUE="\033[34m"
PRINT_PURPLE="\033[35m"
PRINT_CYAN="\033[36m"
PRINT_WHITE="\033[37m"

PRINT_BOLD="\033[1m"

PRINT_RESET="\033[0m"


ECHO_FOUND="${PRINT_GREEN}""FOUND""${PRINT_RESET}"
ECHO_NOT_FOUND="${PRINT_YELLOW}""NOT FOUND""${PRINT_RESET}"

function jaten_assert_param_num() {
    if [ ${#} -lt 3 ]; then
        echo -e "${PRINT_RED}""[ERROR] jaten_assert_param_num : invalid number of params (${#}|3-4). Exit.""${PRINT_RESET}"
        #return
        exit 1
    fi

    if [ ${#} -gt 4 ]; then
        echo -e "${PRINT_RED}""[ERROR] jaten_assert_param_num : invalid number of params (${#}|3-4). Exit.""${PRINT_RESET}"
        #return
        exit 1
    fi


    local FUNCTION_NAME=${1}
    local NUM_OF_PARAM_ACTUAL=${2}
    local NUM_OF_PARAM_NEED_MIN=${3}

    if [ ${#} -eq 3 ]; then
        local NUM_OF_PARAM_NEED_MAX=${NUM_OF_PARAM_NEED_MIN}
    else
        local NUM_OF_PARAM_NEED_MAX=${4}
    fi

    if [ ${NUM_OF_PARAM_NEED_MIN} -gt ${NUM_OF_PARAM_NEED_MAX} ]; then
        echo -e "${PRINT_RED}""[ERROR] jaten_assert_param_num : min[${NUM_OF_PARAM_NEED_MIN}] > max[${NUM_OF_PARAM_NEED_MAX}]. Exit.""${PRINT_RESET}"        
        exit 1
    fi
    
    if [ ${NUM_OF_PARAM_ACTUAL} -lt ${NUM_OF_PARAM_NEED_MIN} ]; then
        echo -e "${PRINT_RED}""[ERROR] ${FUNCTION_NAME} : invalid number of params (${NUM_OF_PARAM_ACTUAL}|${NUM_OF_PARAM_NEED_MIN}-${NUM_OF_PARAM_NEED_MAX}). Exit.""${PRINT_RESET}"
        #return
        exit 1
    fi

    if [ ${NUM_OF_PARAM_ACTUAL} -gt ${NUM_OF_PARAM_NEED_MAX} ]; then
        echo -e "${PRINT_RED}""[ERROR] ${FUNCTION_NAME} : invalid number of params (${NUM_OF_PARAM_ACTUAL}|${NUM_OF_PARAM_NEED_MIN}-${NUM_OF_PARAM_NEED_MAX}). Exit.""${PRINT_RESET}"
        #return
        exit 1
    fi

}



function jaten_get_num_of_contents() {
    jaten_assert_param_num ${FUNCNAME} ${#} 1 2

    local DIR_NAME=${1}
    
    if [ ${#} -lt 2 ]; then
        local LS_SUFFIX=""
    else
        local LS_SUFFIX="${2}"
    fi

    #echo "${DIR_NAME}"
    #echo "${LS_SUFFIX}"

    if [ -z ${LS_SUFFIX} ]; then
        local NUM_OF_CONTENTS=`ls ${DIR_NAME}|wc -w`
    else
        local NUM_OF_CONTENTS=`ls ${DIR_NAME} | grep -e "^.*\."${LS_SUFFIX}"$" | wc -w`
    fi

    return ${NUM_OF_CONTENTS}
    
}




function jaten_generate_dir_name_prefix() {
    jaten_assert_param_num ${FUNCNAME} ${#} 1
    local DIR_NAME=${1}
    local LAST_ID=`ls ${DIR_NAME} | grep -e "^[0-9]\{1,4\}\." | sort -n | tail -n 1 | cut -d'.' -f 1`
    #echo -e "Last ID of Debian packages is ${PRINT_PURPLE}${LAST_ID}${PRINT_RESET}"
    
    local NEW_ID=${LAST_ID}
    let NEW_ID=$((10#${NEW_ID}+1))
    local NEW_ID=`echo ${NEW_ID}|awk '{printf("%04d\n",$0)}'`
    #echo -e "New ID of Debian packages is ${PRINT_PURPLE}${NEW_ID}${PRINT_RESET}"

    echo ${NEW_ID}
}




function jaten_move_cache_deb() {
    
    jaten_assert_param_num ${FUNCNAME} ${#} 2
    

    local DIR_NAME_SUFFIX=${1}
    local RESUME_INSTALL=${2}
    
    if [ ${RESUME_INSTALL} -ne 0 ]; then
        echo -e "Resume previous install, keep the caches."
        return
    fi
    
    jaten_get_num_of_contents ${CACHE_DIR} "deb"
    local NUM_OF_CONTENTS=${?}
    
    if [ ${NUM_OF_CONTENTS} -eq 0 ]; then
        echo -e "No cache found."
        return
    else
        echo -e "Debian package cache found: ${PRINT_PURPLE}${NUM_OF_CONTENTS}${PRINT_RESET}"
    fi 

    local EXISTING_TARGET_DIR=$(ls ${DEB_DIR} | grep -e "^[0-9]*\.${DIR_NAME_SUFFIX}$")
    
    if [ ! -z ${EXISTING_TARGET_DIR} ]; then
        local PARAM_TARGET_DIR="${DEB_DIR}/${EXISTING_TARGET_DIR}"
    else
        local DIR_NAME_PREFIX=$(jaten_generate_dir_name_prefix ${DEB_DIR})
        local PARAM_TARGET_DIR="${DEB_DIR}/${DIR_NAME_PREFIX}.${DIR_NAME_SUFFIX}"
    fi
    
    if [ ! -d ${PARAM_TARGET_DIR} ]; then
        #echo -e "${PRINT_RED}""jaten_move_cache_deb : target directory [${1}] is not a directory""${PRINT_RESET}"
        echo -e "target directory [${PRINT_BLUE}${PARAM_TARGET_DIR}${PRINT_RESET}] ${ECHO_NOT_FOUND}. Creating."
        mkdir -p ${PARAM_TARGET_DIR}
    else
        echo -e "target directory [${PRINT_BLUE}${PARAM_TARGET_DIR}${PRINT_RESET}] ${ECHO_FOUND}."
    fi

    
    echo -e "Moving ${PRINT_PURPLE}${NUM_OF_CONTENTS}${PRINT_RESET} Debian packages."
    sudo mv  ${CACHE_DIR}/*.deb ${PARAM_TARGET_DIR}
    

}




function jaten_install_and_backup_debs() {
    if [ ${#} -gt 0 ]; then
    
        if [ ${1} = "-c" ]; then
            return
        fi
    
        local NAME_CONCACT=""
        for arg in ${*}; do
            local NAME_CONCACT="${NAME_CONCACT}.${arg}"
        done
        
        local NAME_CONCACT=${NAME_CONCACT#*.} # remove the "." dot from the left side

        sudo apt-get install ${*}

        local RETURN_VALUE=${?}
        #echo ${RETURN_VALUE}
        
        if [ ${RETURN_VALUE} -eq 0 ]; then
            echo -e "${PRINT_BLUE}""apt-get ${*} succeded. Moving Debian packages.""${PRINT_RESET}"
            jaten_move_cache_deb ${NAME_CONCACT} 0
            return 0
        else
            echo -e "${PRINT_RED}""[ERROR] apt-get ${*} error. Not moving.""${PRINT_RESET}"
            return ${RETURN_VALUE}
        fi

    fi
}




if [ ! -d ${CACHE_DIR} ]; then
    echo -e "Cache directory [${PRINT_BLUE}${CACHE_DIR}${PRINT_RESET}] ${ECHO_NOT_FOUND}. Creating."
    ln -s /var/cache/apt/archives/ ${HOME}/cache
else
    echo -e "Cache directory [${PRINT_BLUE}${CACHE_DIR}${PRINT_RESET}] ${ECHO_FOUND}."
fi



RESUME_INSTALL=0
if [ ${#} -gt 0 ]; then
    if [ ${1} = "-c" ]; then
        RESUME_INSTALL=1
    fi
fi

jaten_move_cache_deb before.`date +%Y%m%d` ${RESUME_INSTALL}


if [ ${#} -gt 0 ]; then
    for arg in ${*}; do
        jaten_install_and_backup_debs ${arg}
    done
fi


cd ${ORI_DIR}
