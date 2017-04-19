#!/bin/bash

echo "=== start sshd from task scheddduler $(date)  ==" >> ~/sshd_task.txt

[ -d /var/log ] || mkdir -p /var/log
[ -f /etc/ssh/ssh_host_rsa_key ] || ssh-keygen -P "" -f /etc/ssh/ssh_host_rsa_key


PORT="-p 22"

if [ ! -z "$1" ]
then
  PORT=" -p $1"
fi

echo $PORT >> ~/sshd_task.txt

/usr/bin/sshd -D $PORT
