#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.


# fail on error or undefined variable access
set -eu

#------------------------------------------------------------------------------
# global variables
#------------------------------------------------------------------------------
typeset -r script_name="${0##*/}"

#------------------------------------------------------------------------------
# local functions
#------------------------------------------------------------------------------
function usage {
	echo "${script_name} Usage"
	echo "${script_name} must be run by root"
	echo "\t\t${script_name} -s <PRE|POST> [-h]"
	return 0
}

#------------------------------------------------------------------------------
# init
#------------------------------------------------------------------------------
if [[ $(whoami) != "root" ]]; then
	usage && exit 1
fi

while getopts :s:h args; do
	case $args in
		s) typeset -r  mystage="${OPTARG}" ;;
		h) usage ;;
	esac

done

if [[ ${mystage} != @(PRE|POST) ]]; then
	usage && exit 1
fi

#------------------------------------------------------------------------------
# main
#------------------------------------------------------------------------------
if [[ ${mystage} == "PRE" ]]; then
	echo "Installing ords and sqlplus"
	dnf -y install ords oracle-instantclient-release-el8 oracle-instantclient-sqlplus

	echo "Symlinking /etc/init.d/ords to /opt/oracle/ords/ords"
	if [[ ! -f /opt/oracle/ords/ords ]]; then
		ln -s /etc/init.d/ords /opt/oracle/ords/ords
		echo "Symlink'd"
	else
		echo "Symlink already exists"
	fi

	echo "Opening up port 8080 for the ORDS Listener"
	firewall-cmd --zone=public --add-port 8080/tcp --permanent

	echo "Writing /etc/ords/ords.conf"
	cat > /etc/ords/ords.conf <<- EOF
		ORDS_CONFIGDIR=/opt/oracle/ords/config
		JAVA_HOME=/usr/java/latest
		JAVA_OPTIONS=-Xmx2048m
		ORDS_BASE_PATH=/opt/oracle
	EOF
fi

if [[ ${mystage} == "POST" ]]; then
	java -jar -Xmx1024M /opt/oracle/ords/ords.war configdir /opt/oracle/ords/config

	systemctl enable ords
	systemctl restart ords
	systemctl restart firewalld
fi
