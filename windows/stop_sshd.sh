#!/bin/bash

trap '[ "$?" -eq 0 ] || read -p "stop_sshd.sh: Looks like something went wrong in step ´$STEP´... Press any key to continue..."' EXIT

if [ -z "$GREENBOX_INSTALL_PATH" ]
then
  GREENBOX_INSTALL_PATH=/c/G7_bringout
else
  GREENBOX_INSTALL_PATH=$(cygpath $GREENBOX_INSTALL_PATH)
fi

cd $GREENBOX_INSTALL_PATH
source $GREENBOX_INSTALL_PATH/g7_common.sh


#STEP="Is running user greenbox?"
#if [ `whoami` != greenbox ]
#then
#   echo User mora biti greenbox
#   exit 1
#fi

STEP="Check running privileges"
if ! isadmin
then
  echo "You have to run this script as admin user!"
  exit 1
fi

kill_all sshd

#reg delete "HKEY_CURRENT_USER\\Environment" //f //v VBOX_USER_HOME
