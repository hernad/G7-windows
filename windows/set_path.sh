#!/bin/bash

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

VBOX_USER_HOME=$(cygpath $GREENBOX_INSTALL_PATH/.VirtualBox)
export VBOX_USER_HOME=$(cygpath -w $VBOX_USER_HOME)

export PATH=/usr/local/bin:$PATH

export HOME_ORIG=$HOME
export HOME=$GREENBOX_INSTALL_PATH
export TERM=xterm

export HOMEPATH="$GREENBOX_INSTALL_PATH"
#if [ $OS == "W7" ] || [ $OS == "W10" ]
#then
#     HOMEPATH="C:\\Users\\$GREEN_USER"
#else
#     HOMEPATH="C:\\Documents and Settings\\$GREEN_USER"
#fi


export GREEN_SSH_HOME=$(cygpath $HOMEPATH/.ssh)
export GREEN_WINDOWS_HOME=$(cygpath -w $HOMEPATH)


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

# VBoxSVC has to be run with VBOX_USER_HOME set variable
VBoxSVC &

echo "VBoManage list vms ( VBOX_USER_HOME: $VBOX_USER_HOME ):"
VBoxManage list vms
echo -e
echo "VBoManage list runningvms:"
VBoxManage list runningvms
