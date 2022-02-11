#!/usr/bin/env ksh
#------------------------------------------------------------------------------
# GLOBAL/DEFAULT VARS
#------------------------------------------------------------------------------
typeset -i  RC=0
typeset -r  IFS_ORIG=$IFS
typeset -rx SCRIPT_NAME="${0##*/}"

typeset -r CONTEXT="ords"
typeset -r ORDS_DIR="/opt/oracle/ords"
#------------------------------------------------------------------------------
# LOCAL FUNCTIONS
#------------------------------------------------------------------------------
function usage {
	print -- "${SCRIPT_NAME} Usage"
	print -- "${SCRIPT_NAME} MUST be run by root"
	print -- "\t\t${SCRIPT_NAME} -s <PRE|POST> [-h]"
	return 0
}

#------------------------------------------------------------------------------
# INIT
#------------------------------------------------------------------------------
if [[ $(whoami) != "root" ]]; then
	usage && exit 1
fi

while getopts :s:h args; do
	case $args in
		s) typeset -r  MYSTAGE="${OPTARG}" ;;
		h) usage ;;
	esac

done

if [[ ${MYSTAGE} != @(PRE|POST) ]]; then
	usage && exit 1
fi

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------
if [[ ${MYSTAGE} == "PRE" ]]; then
	print -- "Ensuring OCI Repo is enabled"
	yum-config-manager --enable ol7_oci_included

	# print -- "Updating System"
	# yum -y update
  # Takes too long
	
	print -- "Installing ords and yum-cron"
	yum -y install ords yum-cron oracle-instantclient-release-el7
	yum -y install oracle-instantclient-sqlplus

	print -- "Removing dependencies no longer required"
	yum -y autoremove

	print -- "Symlinking /etc/init.d/ords to /opt/oracle/ords/ords"
	if [[ ! -f /opt/oracle/ords/ords ]]; then
		ln -s /etc/init.d/ords /opt/oracle/ords/ords
		print -- "Symlink'd"
	else
		print -- "Symlink already exists"
	fi

	print "Opening up port 8080 for the ORDS Listener"
	firewall-cmd --zone=public --add-port 8080/tcp --permanent

	print -- "Writing /etc/ords/ords.conf"
	cat > /etc/ords/ords.conf <<- EOF
		ORDS_CONFIGDIR=/opt/oracle/ords/config
		JAVA_HOME=/usr/java/latest
		JAVA_OPTIONS=-Xmx2048m
		ORDS_BASE_PATH=/opt/oracle
	EOF
fi

if [[ ${MYSTAGE} == "POST" ]]; then
	java -jar -Xmx1024M /opt/oracle/ords/${CONTEXT}.war configdir /opt/oracle/ords/config

	systemctl enable ords
	systemctl restart ords
	systemctl restart firewalld
fi

return ${RC}
