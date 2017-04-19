#!/bin/bash

trap '[ "$?" -eq 0 ] || read -p "Looks like something went wrong in step ´$STEP´... Press any key to continue..."' EXIT

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

STEP="Is running user greenbox?"
if [ `whoami` != greenbox ]
then
   echo "User mora biti greenbox!"
   exit 1
fi

STEP="Check running privileges"
if ! isadmin
then
  echo "You have to run this script as elevated/privileged user!"
  exit 1
fi

STEP="run cmd for creating tasks and opening firewall"

echo $STEP

./create_tasks.cmd
