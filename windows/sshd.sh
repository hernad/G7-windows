#!/bin/bash

echo "=== start sshd from task scheduler $(date)  ==" >> ~/sshd_task.txt

PORT="-p 22"

if [ ! -z "$1" ]
then
  PORT=" -p $1"
fi

echo $PORT >> ~/sshd_task.txt

/usr/bin/sshd -D $PORT
