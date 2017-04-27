#!/bin/bash

trap '[ "$?" -eq 0 ] || read -p "tasks.sh $1: Looks like something went wrong in step ´$STEP´... Press any key to continue..."' EXIT

if [ -z "$1" ]
then
   echo "./$0 [create|delete]"
   exit 1
fi

function isadmin()
{
    $NET_EXE session > /dev/null 2>&1
    if [ $? -eq 0 ]
    then
       echo "running as admin"
       return 0
    else
       echo "running as standard user"
       return 1
    fi
}

#STEP="Is running user greenbox?"
#if [ `whoami` != greenbox ]
#then
#   echo "User mora biti greenbox!"
#   exit 1
#fi

STEP="Check running privileges"
if ! isadmin
then
  echo "You have to run this script as elevated/privileged user!"
  exit 1
fi



echo $STEP

# ovo je sada u init proceduri
#if [ "$1" == "create" ]
#then
#   STEP="run cmd for creating tasks and opening firewall"
#   ./create_tasks.cmd
#fi

if [ "$1" == "delete" ]
then
   STEP="run cmd for deleting tasks"
   ./delete_tasks.cmd
fi
