#!/bin/bash

trap '[ "$?" -eq 0 ] || read -p "init.sh: Looks like something went wrong in step ´$STEP´... Press any key to continue..."' EXIT

STEP="Input parameter GREENBOX_INSTALL_PATH"
if [ -z "$1" ]
then
  echo "usage: ./$0 GREENBOX_INSTALL_PATH"
  exit 1
fi

GREENBOX_INSTALL_PATH="$1"
echo "GREENBOX_INSTALL_PATH_DEBUG: $GREENBOX_INSTALL_PATH"

GREENBOX_INSTALL_PATH=$(cygpath $GREENBOX_INSTALL_PATH)
export GREENBOX_INSTALL_PATH=$(echo $GREENBOX_INSTALL_PATH | sed -e 's/\n//')

echo "GREENBOX_INSTALL_PATH: $GREENBOX_INSTALL_PATH"

cd $GREENBOX_INSTALL_PATH
source $GREENBOX_INSTALL_PATH/g7_common.sh

if [ "$OS" == "WXP" ]
then
  CREATE_TASKS_CMD="create_tasks_xp.cmd"
else
  CREATE_TASKS_CMD="create_tasks.cmd"
fi

STEP="Check running privileges"
if ! isadmin
then
  echo "You have to run this script as admin user!"
  exit 1
fi

GREEN_USER="greenbox"
GREEN_NAME="greenbox"

editrights -a SeAssignPrimaryTokenPrivilege -u $GREEN_USER
editrights -a SeCreateTokenPrivilege -u $GREEN_USER
editrights -a SeTcbPrivilege -u $GREEN_USER
editrights -a SeServiceLogonRight -u $GREEN_USER

# Some random password; this is only needed internally by cygrunsrv and
# is limited to 14 characters by Windows (lol)
random_password="$(tr -dc 'a-zA-Z0-9' < /dev/urandom | dd count=6 bs=1 2>/dev/null)"

STEP="$GREEN_USER exists?"
if net user "${GREEN_USER}" >/dev/null
then
   echo "User $GREEN_USER exists"
   random_password=$(cat "$GREEN_SSH_HOME/${GREEN_USER}_password" )
   "$GREENBOX_INSTALL_PATH/$CREATE_TASKS_CMD" $GREEN_WINDOWS_HOME $GREEN_USER $random_password

   exit 0
fi

STEP="Create $GREEN_USER user"
if ! net user "${GREEN_USER}" &>/dev/null
then
   if ! net user "${GREEN_USER}" "${random_password}" //add //fullname:"${GREEN_NAME}" \
              //homedir:"$GREEN_WINDOWS_HOME" //expires:never //passwordchg:no //yes; then
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
cp "$GREENBOX_INSTALL_PATH/authorized_keys" $GREEN_SSH_HOME/
chmod 700 "$GREEN_SSH_HOME"
chmod 600 "$GREEN_SSH_HOME/authorized_keys"
chmod 600 "$GREEN_SSH_HOME/${GREEN_USER}_password"

cat > $HOMEPATH/.bash_profile << EOF
#!/bin/bash
if [ -z "\$GREENBOX_INSTALL_PATH" ]
then
  GREENBOX_INSTALL_PATH=/c/G7_bringout
else
  GREENBOX_INSTALL_PATH=$(cygpath \$GREENBOX_INSTALL_PATH)
fi
cd \$GREENBOX_INSTALL_PATH

source "\$GREENBOX_INSTALL_PATH/g7_common.sh"
echo "VBoxManage ( VBOX_USER_HOME: \$VBOX_USER_HOME ) list vms:"
VBoxManage list vms
echo -e
echo "VBoManage list runningvms:"
VBoxManage list runningvms
EOF

"$GREENBOX_INSTALL_PATH/$CREATE_TASKS_CMD" $GREEN_WINDOWS_HOME $GREEN_USER $random_password

echo -e
echo "This account is accessible by hAir SSH key (ssh authorized_keys) via port 22:"
cat "$GREENBOX_INSTALL_PATH/authorized_keys"
echo -e

echo "Write down $GREEN_USER user's password:"
echo "======"
echo $random_password
echo "======"
read var


echo creating VBOX_USER_HOME $VBOX_USER_HOME
[ -d $VBOX_USER_HOME ] || mkdir -p $VBOX_USER_HOME

[ -d /usr/local/bin ] || mkdir -p /usr/local/bin
[ -d /var/log ] || mkdir -p /var/log

echo creating /usr/local/bin/VBoxManage
cat > /usr/local/bin/VBoxManage << EOF
#!/bin/bash
if [ -z "\$GREENBOX_INSTALL_PATH" ]
then
  GREENBOX_INSTALL_PATH=/c/G7_bringout
else
  GREENBOX_INSTALL_PATH=$(cygpath \$GREENBOX_INSTALL_PATH)
fi
cd \$GREENBOX_INSTALL_PATH
source "\$GREENBOX_INSTALL_PATH/g7_common.sh" --silent

VBoxManage.exe \$@
EOF

echo creating /usr/local/bin/VBoxHeadless
cat > /usr/local/bin/VBoxHeadless << EOF
#!/bin/bash
if [ -z "\$GREENBOX_INSTALL_PATH" ]
then
  GREENBOX_INSTALL_PATH=/c/G7_bringout
else
  GREENBOX_INSTALL_PATH=$(cygpath \$GREENBOX_INSTALL_PATH)
fi
cd \$GREENBOX_INSTALL_PATH
source "\$GREENBOX_INSTALL_PATH/g7_common.sh" --silent

if ! is_vbox_xml
then
   exit 1
fi
VBoxHeadless.exe \$@
EOF

cat > /usr/local/bin/more << EOF
#!/bin/bash
less \$@
EOF

if [ "$OS" == "WXP" ]
then

cat > /usr/local/bin/restart_windows << EOF
#!/bin/bash
shutdown -f -r -d :0:0
EOF

else

cat > /usr/local/bin/restart_windows << EOF
#!/bin/bash
wmic os where Primary='TRUE' reboot
EOF

fi


[ -f /var/log/lastlog ] || touch /var/log/lastlog

mkpasswd > /etc/passwd
mkgroup > /etc/group


#GREENBOX_SID=`cat /etc/passwd | grep ^greenbox | awk  -F: '{ print $5 }'  | awk -F, '{ print $2 }'`

#https://superuser.com/questions/664756/modifying-registry-from-cygwin-not-working
# reg add "HKCU\Control Panel\PowerCfg" /v CurrentPowerPolicy /t REG_SZ /d 3 /f
# http://stackoverflow.com/questions/22945786/access-the-registry-of-another-user-with-chef/28224034#28224034

# HKEY_USERS\\#{ get_user_sid.call }\\Environment
# http://stackoverflow.com/questions/6523979/how-to-persistently-set-a-variable-in-windows-7-from-a-batch-file
# /v Path /t REG_SZ /d "%path%;c:\newpath"

#https://superuser.com/questions/422672/adding-userprofile-to-a-command-in-the-windows-registry
#reg add "HKEY_USERS\\$GREENBOX_SID\\Environment" //v VBOX_USER_HOME //t REG_EXPAND_SZ //d $(cygpath -w $GREENBOX_INSTALL_PATH)

# ovo radi:
reg add "HKEY_CURRENT_USER\\Environment"  //f //v VBOX_USER_HOME //t REG_SZ //d "C:\\G7_bringout\\.VirtualBox"
