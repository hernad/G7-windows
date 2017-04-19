#!/bin/bash

trap '[ "$?" -eq 0 ] || read -p "Looks like something went wrong in step ´$STEP´... Press any key to continue..."' EXIT

START_PARAM="interactive"
if [ ! -z "$1"  ]
then
  START_PARAM="$1"
  export VBOX_USER_HOME="$HOMEPATH/.VirtualBox"
fi

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
   echo User mora biti greenbox
   exit 1
fi

STEP="Check running privileges"
if isadmin
then
  echo "You have to run this script as standard user!"
  exit 1
fi

# TODO: I'm sure this is not very robust.  But, it is needed for now to ensure
# that binaries provided by G7_greenbox over-ride binaries provided by
# Docker for Windows when launching using the Quickstart.
PF=$(cygpath $PROGRAMFILES)
PF=$(echo $PF | sed -e 's/\n//')
export PATH="$PF/G7_greenbox:$PATH"
#echo "exe PATH=$PATH"

if [ ! -z "$VBOX_MSI_INSTALL_PATH" ]; then
  VBOX_INSTALL_PATH=$(cygpath $VBOX_MSI_INSTALL_PATH)
  VBOX_INSTALL_PATH=$(echo $VBOX_INSTALL_PATH | sed -e 's/\n//')
  export PATH="${VBOX_INSTALL_PATH}":$PATH
else
  VBOX_INSTALL_PATH=${VBOX_INSTALL_PATH:-$PF/Oracle/VirtualBox/}
  export PATH="${VBOX_INSTALL_PATH}":$PATH
fi

echo $PATH

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
  echo "Docker Machine is not installed. Please re-run the Toolbox Installer and try again."
  exit 1
fi


if  ! which $VBOX_MANAGE 2> /dev/null ; then
  echo "VirtualBox is not installed. Please re-run the Toolbox Installer and try again."
  exit 1
fi

"${VBOX_MANAGE}" list vms | grep \""${VM}"\" &> /dev/null
VM_EXISTS_CODE=$?

#set -e

if [ "$START_PARAM" == "boot" ]
then
   echo "--- start via task scheduler on boot $(date) ---"
   set >> ~/start_on_boot.log
   echo "VBOX_USER_HOME: $VBOX_USER_HOME" >> ~/start_on_boot.log
   $VBOX_MANAGE list vms >> ~/start_on_boot.log
fi

STEP="Checking if machine $VM exists"
if [  $START_PARAM == "interactive" ] && [ $VM_EXISTS_CODE -eq 1 ]; then

  # kada se via task scheduler pokrene ovo ne radi kako treba
  "${DOCKER_MACHINE}" rm -f "${VM}" &> /dev/null || :
  rm -rf ~/.docker/machine/machines/"${VM}"


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
