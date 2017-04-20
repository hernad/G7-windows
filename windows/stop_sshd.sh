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


SSHDPIDS=$(ps -W | grep sshd | grep -v grep | awk '{ print $1 }')

for pid in $SSHDPIDS
do
  echo "killing sshd pid $pid"
  kill $pid
done
