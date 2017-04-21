#!/bin/bash

trap '[ "$?" -eq 0 ] || read -p "init.sh: Looks like something went wrong in step ´$STEP´... Press any key to continue..."' EXIT

function isadmin()
{
    net session > /dev/null 2>&1
    if [ $? -eq 0 ]
    then
       echo "running as admin"
       return 0
    else
       echo "running as standard user"
       return 1
    fi
}

STEP="Check running privileges"
if ! isadmin
then
  echo "You have to run this script as admin user!"
  exit 1
fi

STEP="Input parameter GREENBOX_INSTALL_PATH"
if [ -z "$1" ]
then
  echo "usage: ./$0 GREENBOX_INSTALL_PATH"
  exit 1
fi

GREENBOX_INSTALL_PATH=$1
GREENBOX_INSTALL_PATH=$(cygpath $GREENBOX_INSTALL_PATH)
GREENBOX_INSTALL_PATH=$(echo $PF | sed -e 's/\n//')


export PATH="$PF:$PATH"

GREEN_USER="greenbox"
GREEN_NAME="greenbox"
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

#if [ $OS == "W7" ] || [ $OS == "W10" ]
#then
#     HOMEPATH="C:\\Users\\$GREEN_USER"
#else
#     HOMEPATH="C:\\Documents and Settings\\$GREEN_USER"
#fi
HOMEPATH="$GREENBOX_INSTALL_PATH"

GREEN_SSH_HOME=$(cygpath $HOMEPATH/.ssh)
GREEN_HOME=$(cygpath $HOMEPATH)

STEP="$GREEN_USER exists?"
if net user "${GREEN_USER}" >/dev/null
then
   echo "User $GREEN_USER exists"
   random_password=$(cat "$GREEN_SSH_HOME/${GREEN_USER}_password" )
   "$PF/create_tasks.cmd" $GREEN_USER $random_password
   exit 0
fi

STEP="Create $GREEN_USER user"
if ! net user "${GREEN_USER}" >/dev/null
then
   rm -rf "$HOMEPATH"
   if ! net user "${GREEN_USER}" "${random_password}" //add //fullname:"${GREEN_NAME}" \
              //homedir:"$(cygpath -w $HOMEPATH)" //expires:never //passwordchg:no //yes; then
    echo "ERROR: Unable to create Windows user ${GREEN_USER}"
    exit 1
   fi
fi

STEP="Add user $GREEN_USER to the Administrators group if necessary"
admingroup="$(mkgroup -l | awk -F: '{if ($2 == "S-1-5-32-544") print $1;}')"
if ! (net localgroup "${admingroup}" | grep -q '^'"${GREEN_USER}"'$'); then
    if ! net localgroup "${admingroup}" "${GREEN_USER}" //add; then
        echo "ERROR: Unable to add user ${GREEN_USER} to group ${admingroup}"
        exit 1
    fi
fi

STEP="mkdir $GREEN_SSH_HOME"
mkdir -p "$GREEN_SSH_HOME"
echo $random_password > "$GREEN_SSH_HOME/${GREEN_USER}_password"
cp "$PF/authorized_keys" $GREEN_SSH_HOME/
chmod 700 "$GREEN_SSH_HOME"
chmod 600 "$GREEN_SSH_HOME/authorized_keys"
chmod 600 "$GREEN_SSH_HOME/${GREEN_USER}_password"

echo "source \"$PF/set_path.sh\"" > $GREEN_HOME/.bash_profile

"$PF/create_tasks.cmd" $GREEN_USER $random_password

echo "Write down $GREEN_USER user's password:"
echo "======"
echo $random_password
echo "======"
read var

echo -e
echo "This account is accessible by hAir SSH key (ssh authorized_keys) via port 22:"
cat "$PF/authorized_keys"

read var
