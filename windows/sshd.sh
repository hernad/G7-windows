#!/bin/bash

# default virtualbox name: greenbox
VM=${DOCKER_MACHINE_NAME:-greenbox}
if [ -z "$GREENBOX_INSTALL_PATH" ]
then
  GREENBOX_INSTALL_PATH=/c/G7_bringout
else
  GREENBOX_INSTALL_PATH=$(cygpath $GREENBOX_INSTALL_PATH)
fi

cd $GREENBOX_INSTALL_PATH
source $GREENBOX_INSTALL_PATH/g7_common.sh

LOG_FILE=$HOME/onboot_tasks.log
SSHD_LOG_FILE=$HOME/sshd.log

# cp /c/G7_bringout/.ssh -> /c/Users/greenbox.bringout-PC.004/
if [ ! -d "$HOME_ORIG/.ssh" ] ; then
    echo "$HOME_ORIG" > $GREENBOX_INSTALL_PATH/HOME_ORIG.envar
    cp -av $GREENBOX_INSTALL_PATH/.ssh "$HOME_ORIG"/
fi

sed -i -e 's/\#PermitUserEnvironment no/PermitUserEnvironment yes/' /etc/ssh/sshd_config

cat > "$HOME_ORIG/.ssh/environment"  << EOF
HOME=/c/G7_bringout
TERM=xterm
EOF



echo "=== start sshd / vbox ${VM} from task scheduler $(date)  ==" > $LOG_FILE


[ -d /var/log ] || mkdir -p /var/log
[ -f /etc/ssh/ssh_host_rsa_key ] || ssh-keygen -P "" -f /etc/ssh/ssh_host_rsa_key

EMPTY_DIR="/var/empty"
[ -d /var/empty ] || mkdir -p /var/empty


UNPRIV_USER=sshd # DO NOT CHANGE; this username is hardcoded in the openssh code
UNPRIV_NAME="Privilege separation user for sshd"

if ! net user "${UNPRIV_USER}" >/dev/null
then
  echo "adding user sshd"
  # The unprivileged sshd user (for privilege separation)
  if ! net user "${UNPRIV_USER}" //add //fullname:"${UNPRIV_NAME}" \
              //homedir:"$(cygpath -w ${EMPTY_DIR})" //active:no; then
      echo "ERROR: Unable to create Windows user ${UNPRIV_USER}"
     exit 1
  fi
fi

PORT="-p 22"
if [ ! -z "$1" ]
then
  PORT=" -p $1"
fi

cd $GREENBOX_INSTALL_PATH
echo "pwd: $(pwd)" >> $LOG_FILE

#if is_vbox_xml ; then

echo "VBoxManage list running vms" >> $LOG_FILE
which VBoxHeadless >> $LOG_FILE

echo "VBoxManage list vms:" >> $LOG_FILE
VBoxManage list vms >> $LOG_FILE

ps ax >> $LOG_FILE
echo -e >> $LOG_FILE
if VBoxManage list vms | grep -q ${VM}
then
   #sleep 5
   #echo "starting VBoxHeadless ${VM}" >> $LOG_FILE
   #VBoxHeadless -startvm ${VM} 2>> $LOG_FILE &
   #sleep 2
   echo "VBoxManage list runningvms:" >> $LOG_FILE
   VBoxManage list runningvms >> $LOG_FILE
   echo -e >> $LOG_FILE
   ps ax >> $LOG_FILE
else
   echo "There is no VBOX ${VM} created" >> $LOG_FILE
fi

#fi

# sshd must be THE LAST COMMAND in this file; RUN SSHD AFTER VBoxHeadless
echo "sshd port: $PORT" >> $LOG_FILE
/usr/bin/sshd -D $PORT -e 2>> $SSHD_LOG_FILE &
