#!/bin/bash

# default virtualbox name: greenbox
VM=${DOCKER_MACHINE_NAME:-greenbox}

if [ -z "$GREENBOX_INSTALL_PATH" ]
then
  GREENBOX_INSTALL_PATH=/c/G7_bringout
else
  GREENBOX_INSTALL_PATH=$(cygpath $GREENBOX_INSTALL_PATH)
fi

HOME_ORIG=$HOME
export HOME=$GREENBOX_INSTALL_PATH
export TERM=xterm

LOG_FILE=$HOME/onboot_tasks.log

# cp /c/G7_bringout/.ssh -> /c/Users/greenbox.bringout-PC.004/
[ -d "$HOME_ORIG/.ssh" ] || cp -av $GREENBOX_INSTALL_PATH/.ssh "$HOME_ORIG"/

sed -i -e 's/\#PermitUserEnvironment no/PermitUserEnvironment yes/' /etc/ssh/sshd_config

cat > "$HOME_ORIG/.ssh/environment"  << EOF
HOME=/c/G7_bringout
TERM=xterm
EOF


cat > "$HOME/.bash_profile"  << EOF
#!/bin/bash
source ~/set_path.sh
cd
echo -e
echo "HOME=\$(pwd)"
EOF


cd $GREENBOX_INSTALL_PATH
source $GREENBOX_INSTALL_PATH/set_path.sh

echo "=== start sshd / vbox ${VM} from task scheduler $(date)  ==" > $LOG_FILE


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
    echo "ERROR: Unable to create Windows user ${UNPRIV_USER}"
    exit 1
fi

PORT="-p 22"
if [ ! -z "$1" ]
then
  PORT=" -p $1"
fi

cd $GREENBOX_INSTALL_PATH
echo "pwd: $(pwd)" >> $LOG_FILE

echo "VBoxManage list running vms" >> $LOG_FILE
which VBoxHeadless >> $LOG_FILE

echo "VBoxManage list vms:" >> $LOG_FILE
VBoxManage list vms >> $LOG_FILE

ps ax >> $LOG_FILE
echo -e >> $LOG_FILE
if VBoxManage list vms | grep -q ${VM}
then
   sleep 5
   echo "starting VBoxHeadless ${VM}" >> $LOGFILE
   VBoxHeadless -startvm ${VM} 2>> $LOG_FILE &
   sleep 2
fi
echo "VBoxManage list runningvms:" >> $LOG_FILE
VBoxManage list runningvms >> $LOG_FILE
echo -e >> $LOG_FILE
ps ax >> $LOG_FILE

# sshd must be THE LAST COMMAND in this file; RUN SSHD AFTER VBoxHeadless
echo "sshd port: $PORT" >> $LOG_FILE
/usr/bin/sshd -D $PORT 2 >> $LOG_FILE &
