#!/bin/bash

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
  export PATH="${VBOX_INSTALL_PATH}":$PATH
else
  VBOX_INSTALL_PATH=${VBOX_INSTALL_PATH:-$PF/Oracle/VirtualBox/}
  export PATH="${VBOX_INSTALL_PATH}":$PATH
fi

export VBOX_USER_HOME=$(cygpath $GREENBOX_INSTALL_PATH/.VirtualBox)

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

#echo $PATH
