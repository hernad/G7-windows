#!/bin/bash

# default virtualbox name: greenbox
VM=${DOCKER_MACHINE_NAME:-greenbox}

echo "=== start sshd / vbox ${VM} from task scheduler $(date)  ==" >> ~/sshd_task.txt

if [ ! -z "$VBOX_MSI_INSTALL_PATH" ]; then
  VBOX_INSTALL_PATH=$(cygpath $VBOX_MSI_INSTALL_PATH)
  VBOX_INSTALL_PATH=$(echo $VBOX_INSTALL_PATH | sed -e 's/\n//')
  export PATH="${VBOX_INSTALL_PATH}":$PATH
else
  VBOX_INSTALL_PATH=${VBOX_INSTALL_PATH:-$PF/Oracle/VirtualBox/}
  export PATH="${VBOX_INSTALL_PATH}":$PATH
fi

[ -d /var/log ] || mkdir -p /var/log
[ -f /etc/ssh/ssh_host_rsa_key ] || ssh-keygen -P "" -f /etc/ssh/ssh_host_rsa_key

EMPTY_DIR="/var/empty"
[ -d /var/empty ] || mkdir -p /var/empty

echo "adding user sshd"
UNPRIV_USER=sshd # DO NOT CHANGE; this username is hardcoded in the openssh code
UNPRIV_NAME="Privilege separation user for sshd"
#
# The unprivileged sshd user (for privilege separation)
#
add="$(if ! net user "${UNPRIV_USER}" >/dev/null; then echo "//add"; fi)"
if ! net user "${UNPRIV_USER}" ${add} //fullname:"${UNPRIV_NAME}" \
              //homedir:"$(cygpath -w ${EMPTY_DIR})" //active:no; then
    echo "ERROR: Unable to create Windows user ${PRIV_USER}"
    exit 1
fi


PORT="-p 22"

if [ ! -z "$1" ]
then
  PORT=" -p $1"
fi

echo "sshd port: $PORT" >> ~/sshd_task.txt
which VBoxHeadless >> ~/sshd_tasks.txt

VBoxHeadless -startvm ${VM} &

/usr/bin/sshd -D $PORT
