#!/bin/sh
#
#  configure sshd on Git for Windows and run it as a Windows service
#  References:
#  - https://ghc.haskell.org/trac/ghc/wiki/Building/Windows/SSHD
#  - gist https://gist.github.com/samhocevar/00eec26d9e9988d080ac

#set -e

#
# Configuration
#

SERVICE_NAME=sshgit
PRIV_USER=sshgit
PRIV_NAME="Privileged user for sshd git"

UNPRIV_USER=sshd # DO NOT CHANGE; this username is hardcoded in the openssh code
UNPRIV_NAME="Privilege separation user for sshd"

EMPTY_DIR=/var/empty

[ -d /var/empty ] || mkdir -p /var/empty
[ -d /var/log ] || mkdir -p /var/log

[ -f /etc/ssh/ssh_host_rsa_key ] || ssh-keygen -P "" -f /etc/ssh/ssh_host_rsa_key

#mkpasswd > /etc/passwd
mkgroup > /etc/group

cp -av cygrunsrv.exe /usr/bin/
cp -av editrights.exe /usr/bin/

#
# The privileged cyg_server user
#

# Some random password; this is only needed internally by cygrunsrv and
# is limited to 14 characters by Windows (lol)
tmp_pass="$(tr -dc 'a-zA-Z0-9' < /dev/urandom | dd count=14 bs=1 2>/dev/null)"

# Create user
add="$(if ! net user "${PRIV_USER}" >/dev/null; then echo "//add"; fi)"
if ! net user "${PRIV_USER}" "${tmp_pass}" ${add} //fullname:"${PRIV_NAME}" \
              //homedir:"$(cygpath -w ${EMPTY_DIR})" //yes; then
    echo "ERROR: Unable to create Windows user ${PRIV_USER}"
    exit 1
fi

# Add user to the Administrators group if necessary
admingroup="$(mkgroup -l | awk -F: '{if ($2 == "S-1-5-32-544") print $1;}')"
if ! (net localgroup "${admingroup}" | grep -q '^'"${PRIV_USER}"'$'); then
    if ! net localgroup "${admingroup}" "${PRIV_USER}" //add; then
        echo "ERROR: Unable to add user ${PRIV_USER} to group ${admingroup}"
        exit 1
    fi
fi

# Infinite passwd expiry
passwd -e "${PRIV_USER}"

# set required privileges
for flag in SeAssignPrimaryTokenPrivilege SeCreateTokenPrivilege \
  SeTcbPrivilege SeDenyRemoteInteractiveLogonRight SeServiceLogonRight; do

  if ! editrights -a "${flag}" -u "${PRIV_USER}"; then
        echo "ERROR: Unable to give ${flag} rights to user ${PRIV_USER}"
	exit
  fi

done


#
# The unprivileged sshd user (for privilege separation)
#

add="$(if ! net user "${UNPRIV_USER}" >/dev/null; then echo "//add"; fi)"
if ! net user "${UNPRIV_USER}" ${add} //fullname:"${UNPRIV_NAME}" \
              //homedir:"$(cygpath -w ${EMPTY_DIR})" //active:no; then
    echo "ERROR: Unable to create Windows user ${PRIV_USER}"
    exit 1
fi


#
# Add or update /etc/passwd entries
#

touch /etc/passwd
for u in "${PRIV_USER}" "${UNPRIV_USER}"; do
    sed -i -e '/^'"${u}"':/d' /etc/passwd
    SED='/^'"${u}"':/s?^\(\([^:]*:\)\{5\}\).*?\1'"${EMPTY_DIR}"':/bin/false?p'
    mkpasswd -l -u "${u}" | sed -e 's/^[^:]*+//' | sed -ne "${SED}" \
             >> /etc/passwd
done


#
# Finally, register service with cygrunsrv and start it
#

cygrunsrv -R $SERVICE_NAME || true
cygrunsrv -I $SERVICE_NAME -d "SSHD Git" -p \
          /usr/bin/sshd.exe -a "-D -e" -y tcpip -u "${PRIV_USER}" -w "${tmp_pass}"

# The SSH service should start automatically when Windows is rebooted. You can
# manually restart the service by running `net stop sshd` + `net start sshd`
if ! net start $SERVICE_NAME; then
    echo "ERROR: Unable to start sshd service"
    exit 1
fi
