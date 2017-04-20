#!/bin/bash

PF=$(cygpath $PROGRAMFILES)
PF=$(echo $PF | sed -e 's/\n//')
PF=$PF/G7_greenbox

export PATH="$PF:$PATH"

GREEN_USER=greenbox
GREEN_NAME="greenbox vbox system user"
# Some random password; this is only needed internally by cygrunsrv and
# is limited to 14 characters by Windows (lol)
random_password="$(tr -dc 'a-zA-Z0-9' < /dev/urandom | dd count=6 bs=1 2>/dev/null)"

OS="W10"
if uname -s | grep -q 5.1
then
  OS="WXP"
fi
if uname -s | grep -q 6.1
then
  OS="W7"
fi

if [ $OS == "W7" ] || [ $OS == "W10" ]
then
     export HOMEPATH="C:\\Users\\$GREEN_USER"
else
     export HOMEPATH="C:\\Documents and Settings\\$GREEN_USER"
fi

# Create greenbox user
add="$(if ! net user "${GREEN_USER}" >/dev/null; then echo "//add"; fi)"
if ! net user "${GREEN_USER}" "${random_password}" ${add} //fullname:"${GREEN_NAME}" \
              //homedir:"$HOMEPATH" //yes; then
    echo "ERROR: Unable to create Windows user ${GREEN_USER}"
    exit 1
fi

GREEN_SSH_HOME=$(cygpath $HOMEPATH/.ssh)

mkdir -p $GREEN_SSH_HOME
echo $random_password > $GREEN_SSH_HOME/${GREEN_USER}_password
cp $PF/authorized_keys $GREEN_SSH_HOME/
chmod 700 $GREEN_SSH_HOME
chmod 600 $GREEN_SSH_HOME/authorized_keys
chmod 600 $GREEN_SSH_HOME/${GREEN_USER}_password


$PF/create_tasks.cmd $GREEN_USER $random_password

echo "Write down $GREEN_USER user's password:"
echo "======"
echo $random_password
echo "======"
read var
