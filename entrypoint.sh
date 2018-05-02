#!/bin/bash
set -e

# Still running as root

TARGET_UID="$1"
shift
TARGET_GID="$1"
shift
USER_ARGS="$@"

if grep ${TARGET_UID} /etc/passwd; then
    # A user with the target UID already exists.
    # Setting "jenkins" user's UID to the target UID will fail
    # because it's already taken. In this case, do not touch
    # the UID and simply remember the username to be used later.
    TARGET_USER=$(grep ${TARGET_UID} /etc/passwd | awk -F: '{ print $1 }')
else
    # UID is not taken by any users.
    # Modify "jenkins" user's UID to the target UID
    TARGET_USER="jenkins"
    usermod -u ${TARGET_UID} jenkins
fi

if grep ${TARGET_GID} /etc/group; then
    # A group with the target GID already exists.
    # Setting "jenkins" group's GID to the target GID will fail
    # because it's already taken. In this case, do not touch
    # the gid and simply remember the group name to be used later.
    TARGET_GROUP=$(grep ${TARGET_GID} /etc/group | awk -F: '{ print $1 }')
else
    # GID is not taken by any goups.
    # Modify "jenkins" group's GID to the target GID
    TARGET_GROUP="jenkins"
    groupmod -g ${TARGET_GID} jenkins
fi

# Find all dir & files that were owned by the old jenkins user
# and change ownership to the target user/group.
find / -user 1000 -exec chown ${TARGET_USER} {} \;
find / -group 1000 -exec chgrp ${TARGET_GROUP} {} \;

# Be extra sure to chown JENKINS_HOME (default /var/jenkins_home)
TARGET_HOME=$(getent passwd ${TARGET_USER} | cut -f6 -d:)
chown -R ${TARGET_USER}:${TARGET_GROUP} ${TARGET_HOME}
chown -R ${TARGET_USER}:${TARGET_GROUP} ${JENKINS_HOME}

# Install plugins
if [[ -f "/plugins.txt" ]]; then
    su -m - ${TARGET_USER} -c "/usr/local/bin/install-plugins.sh < /plugins.txt"
fi

# Start Jenkins master
su -m - ${TARGET_USER} -c "/sbin/tini -s -- /usr/local/bin/jenkins.sh $USER_ARGS"

