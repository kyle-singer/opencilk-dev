#!/bin/bash

READLINK=readlink

# Get the absolute path to this file
SCRIPT=$($READLINK -f "$0")

# Get the absolute path to the directory this file is in
SCRIPTPATH=$(dirname "$SCRIPT")

cd ${SCRIPTPATH}

SCRIPT_PARENT=$(dirname "${SCRIPTPATH}")

# This series of commands gets the name of the directory
# we will be mounting
DIRNAME="${SCRIPT_PARENT%"${SCRIPT_PARENT##*[!/]}"}"
DIRNAME="${DIRNAME##*/}"
DIRNAME=${DIRNAME:-/}

# Import the CONTAINER_NAME and CONTAINER_TAG
. ./container.conf

# Mount the home directory so we can persist things
# like the command history, vim settings, etc.
mkdir -p .container-home

# This is where the passwd and group related files will
# be stored (and persisted).
mkdir -p .container-sys

# Get the core dump file size limit
MY_CORE_ULIMIT=$(ulimit -Hc)

REAL_UNAME=$(id -run)
# The script ran via sudo; fix the username and core dump limit
# to match the actual user
if [ "${SUDO_USER}" != "" ]; then
    REAL_UNAME="${SUDO_USER}"
    MY_CORE_ULIMIT=$(su --login ${REAL_UNAME} -c "ulimit -Hc")
fi
REAL_UID=$(id -ru ${REAL_UNAME})
REAL_GID=$(id -rg ${REAL_UNAME})


# docker doesn't understand unlimited, but -1 should work
if [ "${MY_CORE_ULIMIT}" == "unlimited" ]; then
    MY_CORE_ULIMIT=-1
fi

# NOTE: The following docker run command mounts the host /tmp directory
#       because core dumps always end up in the host. To get a core dump,
#       you will need to configure core dumps to output to /tmp.

# Run an interactive (-it) container; use the host network interface
# (net=host); don't implement any security measures to protect the host
# (seccomp=unconfined); remove the container once exited (--rm); mount the path
# above the directory this file is in to /mnt/<directory-name>
# (-v${SCRIPTPATH/..:/mnt/${DIRNAME}); mount the home folder inside the
# container so we can save settings and command history between sessions
# (-v${SCRIPTPATH}/.container-home:/home/dckr-${REAL_UNAME}); mount the host
# /tmp to /tmp (--mount ...); set the working directory to this directory
# (-w=/mnt/${DIRNAME}/scripts); set the coredump ulimit to the same as the host
# (--ulimit core=...); start the container from docker image container name and
# tag (${CONTAINER_NAME}:${CONTAINER_TAG}; pass in "<username> <user_id_#>
# <group_id_#> /bin/bash -l" as arguments to the entrypoint script of the
# container.
docker run -it --net=host --security-opt seccomp=unconfined --rm \
    -v${SCRIPTPATH}/..:/mnt/${DIRNAME} \
    -v${SCRIPTPATH}/.container-home:/home/dckr-${REAL_UNAME} \
    -v${SCRIPTPATH}/.container-sys:/home/dckr-${REAL_UNAME}/.container-sys \
    --mount type=bind,source=/tmp/,target=/tmp/ \
    -w=/mnt/${DIRNAME}/scripts --ulimit core=${MY_CORE_ULIMIT} \
    ${CONTAINER_NAME}:${CONTAINER_TAG} \
    ${REAL_UNAME} ${REAL_UID} ${REAL_GID} /bin/bash -l
