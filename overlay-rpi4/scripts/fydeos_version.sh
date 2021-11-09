#!/bin/bash
meta=$(dirname ${BASH_SOURCE[0]})/../metadata
version_config=${meta}/fydeos_version.txt
#chromeos_tag format:${CHROMEOS_BUILD}.${CHROMEOS_BRANCH}.${CHROMEOS_PATCH}
chromeos_tag="CHROMEOS_VERSION"
build_tag="FYDEOS_BUILD"
release_tag="FYDEOS_RELEASE"

get_data() {
    local tag=$1
    local default=$2
    local data=$(grep ${tag} ${version_config})
    if [ -z "${data}" ]; then
        echo "${default}"
    else
        echo ${data#*=}    
    fi
}

set_data() {
    local tag=$1
    local data=$2
    local predata=$(get_data ${tag})
    if [ -z "${predata}" ]; then
      echo "${tag}=${data}" >> ${version_config}
    else
      sed -i "s/${tag}=.*$/${tag}=${data}/g" ${version_config}    
    fi
}

get_build_number() {
    local chrome_version=$1
    local pre_version=$(get_data ${chromeos_tag})
    local pre_build=$(get_data ${build_tag} 1)
    if [ "${chrome_version}" == "${pre_version}" ]; then
        pre_build=$(($pre_build+1))
    else
        set_data ${chromeos_tag} ${chrome_version}
        pre_build=1
    fi
    set_data ${build_tag} ${pre_build}
    echo ${pre_build}
}

get_fydeos_release_version() {
    get_data ${release_tag}    
}
