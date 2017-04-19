#!/bin/bash

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
  echo "You have to run this script as elevated/privileged user!"
  exit 1
fi

echo "run cmd for creating tasks and opening firewall"

./create_tasks.cmd

