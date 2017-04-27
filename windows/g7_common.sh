#!/bin/bash

NET_EXE=/c/Windows/system32/net.exe

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

# function is_vbox_xml()
# {
#  if [ -f "$VBOX_USER_HOME/VirtualBox.xml" ]
#  then
#     return 0
#  else
#    return 1
#  fi
# }

function kill_all()
{

KILLPROC=$1
KILLPIDS=$(ps -W | grep $KILLPROC | grep -v grep | awk '{ print $1 }')

for pid in $KILLPIDS
do
  #echo "killing $KILPROC pid $pid"
  kill $pid &>/dev/null
done

}

if [ -z "$GREENBOX_INSTALL_PATH" ]
then
  GREENBOX_INSTALL_PATH="C:\\G7_bringout"
fi

export GREENBOX_INSTALL_PATH=$(cygpath $GREENBOX_INSTALL_PATH)

PF=$(cygpath $PROGRAMFILES)
PF=$(echo $PF | sed -e 's/\n//')

export PATH="$GREENBOX_INSTALL_PATH":$PATH
#echo "exe PATH=$PATH"

if [ ! -z "$VBOX_MSI_INSTALL_PATH" ]; then
  VBOX_INSTALL_PATH=$(cygpath $VBOX_MSI_INSTALL_PATH)
  VBOX_INSTALL_PATH=$(echo $VBOX_INSTALL_PATH | sed -e 's/\n//')
  export PATH=$PATH:"${VBOX_INSTALL_PATH}"
else
  VBOX_INSTALL_PATH=${VBOX_INSTALL_PATH:-$PF/Oracle/VirtualBox/}
  export PATH=$PATH:"${VBOX_INSTALL_PATH}"
fi

#VBOX_USER_HOME=$(cygpath $GREENBOX_INSTALL_PATH/.VirtualBox)
#export VBOX_USER_HOME=$(cygpath -w $VBOX_USER_HOME)

#export PATH=/usr/local/bin:$PATH

if [ -f USERPROFILE.envar ] ; then
  export USERPROFILE="$(cat USERPROFILE.envar)"
else
  export USERPROFILE="$HOME"
fi

export HOME=$GREENBOX_INSTALL_PATH
export TERM=xterm

export HOMEPATH="$GREENBOX_INSTALL_PATH"


function set_vbox_user_home() {

  #GREENBOX_SID=`cat /etc/passwd | grep ^greenbox | awk  -F: '{ print $5 }'  | awk -F, '{ print $2 }'`
  reg add "HKEY_CURRENT_USER\\Environment"  //f //v VBOX_USER_HOME //t REG_SZ //d "$VBOX_USER_HOME"

}


function vbox_forward_ports() {

  VM=$1
  VBoxManage controlvm ${VM} savestate

  echo "Setup port forward: HOST 2222, $VM guest port 22"
  VBoxManage modifyvm $VM --natpf1 "ssh-greenbox,tcp,,2222,,22"

  echo "Setup TCP port forward: HOST 2376, $VM guest port 2376"
  VBoxManage modifyvm $VM --natpf1 "docker-greenbox,tcp,,2376,,2376"

  echo "Setup port forward: HOST 80, $VM guest port 80"
  VBoxManage modifyvm $VM --natpf1 "http,tcp,,80,,80"

  echo "Setup port forward: HOST 443, $VM guest port 443"
  VBoxManage modifyvm $VM --natpf1 "https,tcp,,443,,443"

  echo "Setup UDP port forward: HOST 53, $VM guest port 53"
  VBoxManage modifyvm $VM --natpf1 "dns,udp,,53,,53"

  for port in {54320..54330}
  do echo $port ;
    echo "Setup port forward: HOST $port, $1 guest port $port"
    VBoxManage modifyvm $1 --natpf1 "psql$port,tcp,,$port,,$port"
  done

  VBoxManage startvm ${VM}  --type headless
  echo "Wait 2 sec ..."
  sleep 2

}

#function check_vbox_xml() {
##  <MachineEntry uuid="{5aed4ee0-2b4c-4711-bcab-1caab80762b2}" src="C:\G7_bringout\.VirtualBox\.docker\machine\machines\greenbox\greenbox\greenbox.vbox"/>
#if ! cat .VirtualBox/VirtualBox.xml | grep src.*G7_bringout.*greenbox\.vbox
#then
#  echo "find right VirtualBox.xml which contains greenbox.vbox in directory similar to /c/Users/greenbox/.VirtualBox"
#  echo "then move that directory to /c/G7_bringout/.Virtualbox, then fix path in src= section of VirtualBox.xml"
#  echo "test is everything ok by restarting OS"
#  echo -e
#  echo "Press any key to continue ..."
#  read var
#  exit 1
#else
#  echo ".VirtualBox/VirtualBox.xml seems to be OK"
#fi
#}


# http://www.askvg.com/list-of-environment-variables-in-windows-xp-vista-and-7/
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

export GREEN_SSH_HOME=$(cygpath $HOMEPATH/.ssh)
export GREEN_WINDOWS_HOME=$(cygpath -w $HOMEPATH)

if [  "$1" != "--silent"  ] ; then
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
fi
