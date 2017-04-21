#!/bin/bash

trap '[ "$?" -eq 0 ] || read -p "start.sh: Looks like something went wrong in step ´$STEP´... Press any key to continue..."' EXIT

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

function vbox_forward_ports() {
  echo "Setup port forward: HOST 2222, $1 guest port 22"
  VBoxManage modifyvm $1 --natpf1 "ssh,tcp,,2222,,22"

  echo "Setup port forward: HOST 80, $1 guest port 80"
  VBoxManage modifyvm $1 --natpf1 "ssh,tcp,,80,,80"

  echo "Setup port forward: HOST 443, $1 guest port 443"
  VBoxManage modifyvm $1 --natpf1 "ssh,tcp,,443,,443"

  echo "Setup UDP port forward: HOST 53, $1 guest port 53"
  VBoxManage modifyvm $1 --natpf1 "ssh,udp,,53,,53"

  echo "Setup TCP port forward: HOST 2376, $1 guest port 2376"
  VBoxManage modifyvm $1 --natpf1 "ssh,udp,,2376,,2376"

  for port in {54320..54330}
  do echo $port ;
    echo "Setup port forward: HOST $port, $1 guest port $port"
    VBoxManage modifyvm $1 --natpf1 "ssh,tcp,,$port,,$port"
  done

}

#NT-5.0 = W2000 #NT-5.1 = XP #NT-6.0 = Vista #NT-6.1 = W7
OS="W10"
if uname -s | grep -q 5.1
then
  OS="WXP"
fi
if uname -s | grep -q 6.1
then
  OS="W7"
fi

# http://www.askvg.com/list-of-environment-variables-in-windows-xp-vista-and-7/

START_PARAM="interactive"
if [ ! -z "$1"  ]
then
  START_PARAM="$1" # boot

  if [ $OS == "W7" ] || [ $OS == "W10" ]
  then
     export HOMEPATH="\\Users\\greenbox"
  else
     export HOMEPATH="C:\\Documents and Settings\\greenbox"
  fi
  export VBOX_USER_HOME=$(cygpath ~/.VirtualBox)
fi


STEP="Is running user greenbox?"
if [ `whoami` != greenbox ]
then
   echo User mora biti greenbox
   exit 1
fi

STEP="Check running privileges"
if ! isadmin
then
  echo "You have to run this script with admin privileges!"
  exit 1
fi

./set_path.sh

#echo $PATH

# default virtualbox name: greenbox
VM=${DOCKER_MACHINE_NAME:-greenbox}

echo "Setting up vbox machine with 1152 MB RAM/99 GB HDD ..."

#ako zelimo vec gotovu vm importovati --virtualbox-import-greenbox-vm

GREENBOX_VBOX_PARAMS="  --virtualbox-memory 1152"
GREENBOX_VBOX_PARAMS+=" --virtualbox-boot2docker-url http://download.bring.out.ba/greenbox.iso"
GREENBOX_VBOX_PARAMS+=" --virtualbox-disk-size 99000"
#GREENBOX_VBOX_PARAMS+=" --virtualbox-hostonly-cidr 192.168.97.1/24"
#GREENBOX_VBOX_PARAMS+=" --virtualbox-hostonly-nicpromisc deny"
GREENBOX_VBOX_PARAMS+=" --virtualbox-no-vtx-check"

DOCKER_APPDATA=$(cygpath $APPDATA/../.docker | sed -e 's/\n//')

# docker-machine expects boot2docker.iso:
#mkdir -p ~/.docker/machine/cache/
#cp -av "$DOCKER_APPDATA/machine/cache/greenbox.iso"  ~/.docker/machine/cache/boot2docker.iso

DOCKER_MACHINE=docker-machine.exe
VBOX_MANAGE=VBoxManage.exe


BLUE='\033[1;34m'
GREEN='\033[0;32m'
NC='\033[0m'

#clear all_proxy if not socks address
if  [[ $ALL_PROXY != socks* ]]; then
  unset ALL_PROXY
fi
if  [[ $all_proxy != socks* ]]; then
  unset all_proxy
fi

if ! which $DOCKER_MACHINE 2> /dev/null ; then
  echo "Docker Machine is not installed. Please re-run the GreenBox Installer and try again."
  exit 1
fi


if  ! which $VBOX_MANAGE 2> /dev/null ; then
  echo "VirtualBox is not installed. Please re-run the GreenBox Installer and try again."
  exit 1
fi


if [ "$START_PARAM" == "boot" ]
then
   echo "--- start via task scheduler on boot $(date) ---" > ~/start_on_boot.log
   echo "PATH: $PATH" >> ~/start_on_boot.log
   echo "VBOX_USER_HOME: $VBOX_USER_HOME" >> ~/start_on_boot.log
   echo "starting headless $VM" >> ~/start_on_boot.log
   VBoxHeadless -startvm $VM &
   $VBOX_MANAGE list vms &>> ~/start_on_boot.log
   exit 0
fi

"${VBOX_MANAGE}" list vms | grep \""${VM}"\" &> /dev/null
VM_EXISTS_CODE=$?

#set -e

STEP="Checking if machine $VM exists"

if [ $VM_EXISTS_CODE != 0 ] && [  $START_PARAM == "boot" ]
then
   echo "VM $VM error!" >> ~/start_on_boot.log
   exit 1
fi

if [ $VM_EXISTS_CODE != 0 ]
then

  # kada se via task scheduler pokrene ovo ne radi kako treba
  #"${DOCKER_MACHINE}" rm -f "${VM}" &> /dev/null || :
  #rm -rf ~/.docker/machine/machines/"${VM}"

  #set proxy variables if they exists
  if [ "${HTTP_PROXY}" ]; then
    PROXY_ENV="$PROXY_ENV --engine-env HTTP_PROXY=$HTTP_PROXY"
  fi
  if [ "${HTTPS_PROXY}" ]; then
    PROXY_ENV="$PROXY_ENV --engine-env HTTPS_PROXY=$HTTPS_PROXY"
  fi
  if [ "${NO_PROXY}" ]; then
    PROXY_ENV="$PROXY_ENV --engine-env NO_PROXY=$NO_PROXY"
  fi
  "${DOCKER_MACHINE}" create -d virtualbox $PROXY_ENV $GREENBOX_VBOX_PARAMS "${VM}"

  STEP="Waiting for greenbox to install docker ...."

  FAIL=1
  while ! "${DOCKER_MACHINE}" ssh "${VM}" "cat /opt/docker/VERSION"
  do
    echo "$FAIL : $STEP"
    sleep 10
  done

  STEP="Waiting for greenbox to run dockerd ...."
  FAIL=1
  while ! "${DOCKER_MACHINE}" env "${VM}"
  do
     echo "$FAIL : $STEP"
     sleep 5
     "${DOCKER_MACHINE}" regenerate-certs -f "${VM}"
     let "FAIL+=1"

     if [ $FAIL -gt 5 ]
     then
       exit 1
     fi
  done

  vbox_forward_ports ${VM}

fi

STEP="Checking status on $VM"
VM_STATUS="$(${DOCKER_MACHINE} status ${VM} 2>&1)"
if [ "${VM_STATUS}" != "Running" ]
then
  "${DOCKER_MACHINE}" start "${VM}"
fi


STEP="Setting env"
eval "$(${DOCKER_MACHINE} env --shell=bash --no-proxy ${VM})"

STEP="Finalize"
clear
cat << EOF


                        ##         .
                  ## ## ##        ==
               ## ## ## ## ##    ===                 |
           /"""""""""""""""""\___/ ===               | b
      ~~~ {~~ ~~~~ ~~~ ~~~~ ~~~ ~ /  ===- ~~~        | r
           \______ o           __/                   | i
             \    \         __/                      | n
              \____\_______/                         | g
     __ _ _ __ ___  ___ _ __ | |__   _____  __       | .
    / _' | '__/ _ \/ _ \ '_ \| '_ \ / _ \ \/ /       | o
   | (_| | | |  __/  __/ | | | |_) | (_) >  <        | u
    \__, |_|  \___|\___|_| |_|_.__/ \___/_/\_\       | t
    |___/                                            |

EOF
echo -e "${BLUE}docker${NC} is configured to use the ${GREEN}${VM}${NC} machine with IP ${GREEN}$(${DOCKER_MACHINE} ip ${VM})${NC}"
echo "For help getting started, check out the docs at https://github.com/hernad/G7-windows"
echo -e
echo "Check these commands:"
echo "docker-machine ssh ${VM} \"cat /opt/docker/VERSION\", docker-machine env ${VM}, docker-machine ip ${VER}"
echo "docker run -ti alpine sh, docker images, docker ps -a"


docker () {
  MSYS_NO_PATHCONV=1 docker.exe "$@"
}
export -f docker

if [ $# -eq 0 ]; then
  echo "Start interactive shell"
  exec "$BASH" --login -i
else
  echo "Start shell with command"
  exec "$BASH" -c "$*"
fi
