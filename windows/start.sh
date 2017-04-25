#!/bin/bash

trap '[ "$?" -eq 0 ] || read -p "start.sh: Looks like something went wrong in step ´$STEP´... Press any key to continue..."' EXIT
first_install=0

DISK_SIZE=55000
MEM_SIZE=1152

if [ -z "$GREENBOX_INSTALL_PATH" ]
then
  GREENBOX_INSTALL_PATH=/c/G7_bringout
else
  GREENBOX_INSTALL_PATH=$(cygpath $GREENBOX_INSTALL_PATH)
fi
cd $GREENBOX_INSTALL_PATH

source $GREENBOX_INSTALL_PATH/g7_common.sh


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

#echo $PATH

# default virtualbox name: greenbox
VM=${DOCKER_MACHINE_NAME:-greenbox}

echo "Setting up vbox machine with $MEM_SIZE MB RAM/$DISK_SIZE MB HDD ..."

#ako zelimo vec gotovu vm importovati --virtualbox-import-greenbox-vm

GREENBOX_VBOX_PARAMS="  --virtualbox-memory $MEM_SIZE"
GREENBOX_VBOX_PARAMS+=" --virtualbox-boot2docker-url http://download.bring.out.ba/greenbox.iso"
GREENBOX_VBOX_PARAMS+=" --virtualbox-disk-size $DISK_SIZE"
GREENBOX_VBOX_PARAMS+=" --virtualbox-no-vtx-check"
GREENBOX_VBOX_PARAMS+=" --virtualbox-share-folder $(cygpath -w $GREENBOX_INSTALL_PATH):G7_bringout"
GREENBOX_VBOX_PARAMS+=" --virtualbox-ssh-port 2222"

#DOCKER_APPDATA=$(cygpath $APPDATA/../.docker | sed -e 's/\n//')
# docker-machine expects boot2docker.iso:
#mkdir -p ~/.docker/machine/cache/
#cp -av "$DOCKER_APPDATA/machine/cache/greenbox.iso"  ~/.docker/machine/cache/boot2docker.iso

DOCKER_MACHINE=docker-machine
VBOX_MANAGE=VBoxManage


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

STEP="Check which $DOCKER_MACHINE"
if ! which $DOCKER_MACHINE 2> /dev/null ; then
  echo "Docker Machine is not installed. Please re-run the GreenBox Installer and try again."
  exit 1
fi

STEP="Check which $VBOX_MANAGE"
if  ! which $VBOX_MANAGE 2> /dev/null ; then
  echo "VirtualBox is not installed. Please re-run the GreenBox Installer and try again."
  exit 1
fi


"${VBOX_MANAGE}" list vms | grep \""${VM}"\" &> /dev/null
VM_EXISTS_CODE=$?

STEP="Checking does machine $VM exists"

if [ "$VM_EXISTS_CODE" != "0" ]
then

  first_install=1
  docker-machine rm -f ${VM}

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

  STEP="Run docker-machine $GREENBOX_VBOX_PARAMS"
  "${DOCKER_MACHINE}" create -d virtualbox $PROXY_ENV $GREENBOX_VBOX_PARAMS "${VM}"

  vbox_forward_ports ${VM}

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
     "${DOCKER_MACHINE}" ssh "${VM}" "sudo /etc/init.d/docker restart"
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
[  "$first_install" == "0" ] && clear

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


echo "Start interactive shell"
exec "$BASH" --login -i
