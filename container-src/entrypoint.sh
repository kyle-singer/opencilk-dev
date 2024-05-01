#!/bin/bash

# Argument 1 is the username string
UNAME=${1}
# Argument 2 is the user id # (necessary to match host ownership)
HOST_UID=${2}
# Argument 3 is the group id # (necessary to match host ownership)
HOST_GID=${3}

# Prepend dckr to the passed in username string make it obvious we are inside a
# docker container.
DCKR_UNAME="dckr-${UNAME}"
USR_HOME="/home/${DCKR_UNAME}"

# Copy in the previous passwd-related files, if they exist.  Mounting files
# directly to /etc/passwd and /etc/shadow seems to cause issues with persisting
# changes.
if [ -f ${USR_HOME}/.container-sys/passwd ] && \
    [ -f ${USR_HOME}/.container-sys/shadow ]; then

    # Copy in the username and password identifiers
    cp ${USR_HOME}/.container-sys/passwd /etc/passwd
    cp ${USR_HOME}/.container-sys/shadow /etc/shadow
    chmod 644 /etc/passwd
    chmod 644 /etc/shadow

    # Copy in the group identifiers
    cp ${USR_HOME}/.container-sys/group /etc/group
    cp ${USR_HOME}/.container-sys/group /etc/gshadow
    chmod 644 /etc/group
    chmod 644 /etc/gshadow
fi

grep -E "^${DCKR_UNAME}:" /etc/passwd > /dev/null
USER_EXISTS=${?}

# The return code of grep is 0 if found, non-zero if not found.
if [ ${USER_EXISTS} -eq 0 ]; then
    USER_EXISTS=1
else
    USER_EXISTS=0
fi

if [ ${USER_EXISTS} -eq 0 ]; then
    echo "Adding user named ${DCKR_UNAME} to the container."

    # Add a user with username based on DCKR_UNAME. Set the default shell to bash,
    # and add the user to the sudo group so they can invoke sudo.
    useradd -m ${DCKR_UNAME} -s /bin/bash -G sudo > /dev/null 2>&1
fi

# In case files are mounted to the home directory, the skel files
# may not be copied by useradd. Remedy this here, but don't overwrite
# existing files.
cp -nRT /etc/skel ${USR_HOME}/

# Make sure we reference some apt install/update/etc. recording functions
# for convenience
cp /etc/skel/.apt-recording ${USR_HOME}/
grep "\[\[ -f ~/.apt-recording \]\] && . ~/.apt-recording" ${USR_HOME}/.bashrc 2>&1 > /dev/null
[ ${?} -eq 0 ] || echo "[[ -f ~/.apt-recording ]] && . ~/.apt-recording" >> ${USR_HOME}/.bashrc

# Get the current user id # in the docker container;
# This will allow us to find files owned by the new user
# and fix the ownership (note: should just be the home directory
# at the moment).
DCKR_UID=$(id -u ${DCKR_UNAME})

# Change the group id of dcker-UNAME to match the host user's group id.
groupmod -g ${HOST_GID} ${DCKR_UNAME} > /dev/null 2>&1
# Find everything owned by the user we just created (likely just USR_HOME)
# and change the ownership to match the host user and group id numbers.
find / -mount -uid ${DCKR_UID} -exec chown ${HOST_UID}.${HOST_GID} {} \;

# The files we copied from /etc/skel are owned by root; fix that.
chown -R ${DCKR_UNAME}: ${USR_HOME}

# Change the user id number of dcker-UNAME to match the host user's user id.
usermod -u ${HOST_UID} ${DCKR_UNAME} > /dev/null 2>&1

if [ ${USER_EXISTS} -eq 0 ]; then
    # Loop attempting to set a password until we succeed
    # (we do this because we shouldn't really allow passwordless sudo)
    SET_PASSWD_SUCCESS=1
    while [ "${SET_PASSWD_SUCCESS}" != "0" ]; do
        echo "Set a password for sudo access. Must not be empty."
        passwd ${DCKR_UNAME}
        # Check the return code of the passwd program
        SET_PASSWD_SUCCESS=${?}
    done
fi

# Login to an interactive login (--login) session for user DCKR_UNAME, and
# execute commands "cd ${PWD}; ${@:4}", where PWD is the working directory of
# the container, and ${@:4} specifies to execute argument 4 (${4}) with all
# following arguments (e.g. 5 through n) as arguments to ${4}. Note that what
# is actually going on here is we are using ${@:4} to drop the first 4
# arguments to this script (0-3) and only access 4 through n.
su ${DCKR_UNAME} --login --session-command="cd ${PWD}; ${@:4}"

# Copy the passwd and group files back out of the container (for persistence)
# and set the ownership to the host user (for convenience).
cp /etc/passwd ${USR_HOME}/.container-sys/passwd
chown ${HOST_UID}:${HOST_GID} ${USR_HOME}/.container-sys/passwd
cp /etc/shadow ${USR_HOME}/.container-sys/shadow
chown ${HOST_UID}:${HOST_GID} ${USR_HOME}/.container-sys/shadow

cp /etc/group ${USR_HOME}/.container-sys/group
chown ${HOST_UID}:${HOST_GID} ${USR_HOME}/.container-sys/group
cp /etc/gshadow ${USR_HOME}/.container-sys/gshadow
chown ${HOST_UID}:${HOST_GID} ${USR_HOME}/.container-sys/gshadow
