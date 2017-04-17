#!/bin/bash

trap '[ "$?" -eq 0 ] || read -p "Looks like something went wrong in step ´$STEP´... Press any key to continue..."' EXIT

# TODO: I'm sure this is not very robust.  But, it is needed for now to ensure
# that binaries provided by G7_greenbox over-ride binaries provided by
# Docker for Windows when launching using the Quickstart.
PF=$(cygpath $PROGRAMFILES)
PF=$(echo $PF | sed -e 's/\n//')
export PATH="$PF/G7_greenbox:$PATH"
echo "exe PATH=$PATH"
# default virtualbox name: greenbox
VM=${DOCKER_MACHINE_NAME:-greenbox}

#ako zelimo vec gotovu vm importovati --virtualbox-import-greenbox-vm

GREENBOX_VBOX_PARAMS="  --virtualbox-memory 1280"
GREENBOX_VBOX_PARAMS+=" --virtualbox-boot2docker-url http://download.bring.out.ba/greenbox.iso"
GREENBOX_VBOX_PARAMS+=" --virtualbox-disk-size 99000"
#GREENBOX_VBOX_PARAMS+=" --virtualbox-hostonly-cidr 192.168.97.1/24"
#GREENBOX_VBOX_PARAMS+=" --virtualbox-hostonly-nicpromisc deny"

DOCKER_APPDATA=$(cygpath $APPDATA/../.docker | sed -e 's/\n//')

# docker-machine expects boot2docker.iso:
#mkdir -p ~/.docker/machine/cache/
#cp -av "$DOCKER_APPDATA/machine/cache/greenbox.iso"  ~/.docker/machine/cache/boot2docker.iso

DOCKER_MACHINE=./docker-machine.exe

STEP="Looking for vboxmanage.exe"
if [ ! -z "$VBOX_MSI_INSTALL_PATH" ]; then
  VBOXMANAGE="${VBOX_MSI_INSTALL_PATH}VBoxManage.exe"
else
  VBOXMANAGE="${VBOX_INSTALL_PATH}VBoxManage.exe"
fi

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

if [ ! -f "${DOCKER_MACHINE}" ]; then
  echo "Docker Machine is not installed. Please re-run the Toolbox Installer and try again."
  exit 1
fi

if [ ! -f "${VBOXMANAGE}" ]; then
  echo "VirtualBox is not installed. Please re-run the Toolbox Installer and try again."
  exit 1
fi

"${VBOXMANAGE}" list vms | grep \""${VM}"\" &> /dev/null
VM_EXISTS_CODE=$?

set -e

STEP="Checking if machine $VM exists"
if [ $VM_EXISTS_CODE -eq 1 ]; then
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
fi

STEP="Checking status on $VM"
VM_STATUS="$(${DOCKER_MACHINE} status ${VM} 2>&1)"
if [ "${VM_STATUS}" != "Running" ]; then
  "${DOCKER_MACHINE}" start "${VM}"
  yes | "${DOCKER_MACHINE}" regenerate-certs "${VM}"
fi

STEP="Setting env"
eval "$(${DOCKER_MACHINE} env --shell=bash --no-proxy ${VM})"

STEP="Finalize"
clear
cat << EOF


                        ##         .
                  ## ## ##        ==
               ## ## ## ## ##    ===
           /"""""""""""""""""\___/ ===
      ~~~ {~~ ~~~~ ~~~ ~~~~ ~~~ ~ /  ===- ~~~
           \______ o           __/
             \    \         __/
              \____\_______/

EOF
echo -e "${BLUE}docker${NC} is configured to use the ${GREEN}${VM}${NC} machine with IP ${GREEN}$(${DOCKER_MACHINE} ip ${VM})${NC}"
echo "For help getting started, check out the docs at https://docs.docker.com"
echo
cd

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
