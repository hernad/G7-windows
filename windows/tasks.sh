#!/bin/bash

trap '[ "$?" -eq 0 ] || read -p "tasks.sh $1: Looks like something went wrong in step ´$STEP´... Press any key to continue..."' EXIT

if [ -z "$GREENBOX_INSTALL_PATH" ]
then
  GREENBOX_INSTALL_PATH=/c/G7_bringout
else
  GREENBOX_INSTALL_PATH=$(cygpath $GREENBOX_INSTALL_PATH)
fi
cd $GREENBOX_INSTALL_PATH

source $GREENBOX_INSTALL_PATH/g7_common.sh

if [ -z "$1" ]
then
   echo "./$0 [create|delete]"
   exit 1
fi


STEP="Check running privileges"
if ! isadmin
then
  echo "You have to run this script as elevated/privileged user!"
  exit 1
fi



echo $STEP

if [ "$1" == "delete" ]
then
   STEP="run cmd for deleting tasks"
   ./delete_tasks.cmd
fi
