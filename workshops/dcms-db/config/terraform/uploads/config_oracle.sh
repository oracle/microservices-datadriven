#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.


# fail on error or undefined variable access
set -eu

#------------------------------------------------------------------------------
# vars
#------------------------------------------------------------------------------
typeset -i  rc=0
typeset -rx script_name="${0##*/}"
typeset -rx script_dir="/tmp/uploads"

typeset -r ords_dir="/opt/oracle/ords"
typeset -r ords_user="ORDS_PUBLIC_USER_OCI"
typeset -r ords_plgw="ORDS_PLSQL_GATEWAY_OCI"

#------------------------------------------------------------------------------
# LOCAL FUNCTIONS
#------------------------------------------------------------------------------
function usage {
	echo "${script_name} Usage"
	echo "${script_name} MUST be run by oracle"
	echo "\t\t${script_name} -t <DB_NAME> -p <ADMIN_PASS> -v <APEX_VERSION> [-h]"
	return 0
}

function grabdish_db_setup {
	typeset -r _pass=$1
	typeset -r _db_alias=$2
	typeset -r _queue_type=$3

	db_script_home=/tmp/uploads/db
	cd
	target_db_script_home=`pwd`/db
	mkdir -p ${target_db_script_home}

	# source the script params
	DB_PASSWORD=${_pass}
	QUEUE_TYPE=${_queue_type}
	DB1_ALIAS=${_db_alias}
	source ${db_script_home}/params.env

	# expand the common scripts
	target_common_script_home=${target_db_script_home}/common/apply
	if ! test -d ${target_common_script_home}; then
		mkdir -p ${target_common_script_home}
		cd ${db_script_home}/common/apply
		for f in $(ls); do
		  eval "
			cat >${target_common_script_home}/${f} <<- !
			$(<${f})
			!
			"
		  chmod 400 ${target_common_script_home}/${f}
		done
  fi

	# execute the apply sql scripts in order
	target_apply_script_home=${target_db_script_home}/1db/apply
	mkdir -p ${target_apply_script_home}
  cd ${db_script_home}/1db/apply
	for f in $(ls); do
		target=${target_apply_script_home}/${f}
		cd ${target_apply_script_home}
		if ! test -f ${target}; then
			echo "Executing ${target}"
		  eval "
			cat >${target} <<- !
				set serveroutput on size 99999 feedback off timing on linesize 180 echo on
				whenever sqlerror exit 1
				$(<${db_script_home}/1db/apply/${f})
			!
			"
			chmod 400 ${target}
			sqlplus /nolog <${target}
		fi
	done
}

function run_sql {
	typeset -i _RC=0
	typeset -r _PASS=$1
	typeset -r _DBNAME=$2
	typeset -r _SQL=$3

	echo "Connnecting to ${_DBNAME}_TP (TNS_ADMIN=$TNS_ADMIN)"
	sqlplus -s /nolog <<-EOSQL
		connect ADMIN/${_PASS}@${_DBNAME}_TP
		set serveroutput on size 99999 feedback off timing on linesize 180 echo on
		whenever sqlerror exit 1
		$_SQL
	EOSQL

	return ${_RC}
}

function create_user {
	typeset -i _RC=0
	typeset -r _PASS=$1
	typeset -r _DBNAME=$2
	typeset -r _USERNAME=$3

	typeset -r _CREATE_USER="
		DECLARE
			L_USER  VARCHAR2(255);
		BEGIN
			DBMS_OUTPUT.PUT_LINE('Configuring ${_USERNAME}');
			BEGIN
				SELECT USERNAME INTO L_USER FROM DBA_USERS WHERE USERNAME='${_USERNAME}';
				DBMS_OUTPUT.PUT_LINE('Modifying ${_USERNAME}');
				execute immediate 'ALTER USER \"${_USERNAME}\" IDENTIFIED BY \"${_PASS}\"';
			EXCEPTION WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('Creating ${_USERNAME}');
				execute immediate 'CREATE USER \"${_USERNAME}\" IDENTIFIED BY \"${_PASS}\"';
			END;
		END;
		/
		GRANT CONNECT TO ${_USERNAME};
		ALTER USER ${_USERNAME} PROFILE ORA_APP_PROFILE;"

	run_sql "${_PASS}" "${_DBNAME}" "${_CREATE_USER}"
	_RC=$?

	return ${_RC}
}

function config_user {
	typeset -i _RC=0
	typeset -r _PASS=$1
	typeset -r _DBNAME=$2

	create_user "${_PASS}" "${_DBNAME}" "${ords_user}"
	_RC=$?

	create_user "${_PASS}" "${_DBNAME}" "${ords_plgw}"
	_RC=$(( _RC + $? ))

	if (( _RC == 0 )); then
		typeset -r _PUBLIC_SQL="
			BEGIN
				DBMS_OUTPUT.PUT_LINE('Giving ${ords_user} the Runtime Role');
				ORDS_ADMIN.PROVISION_RUNTIME_ROLE (
					p_user => '${ords_user}',
					p_proxy_enabled_schemas => TRUE
				);
			END;
			/"

		run_sql "${_PASS}" "${_DBNAME}" "${_PUBLIC_SQL}"

		typeset -r _GATEWAY_SQL="
			ALTER USER ${ords_plgw} GRANT CONNECT THROUGH ${ords_user};
			BEGIN
				ORDS_ADMIN.CONFIG_PLSQL_GATEWAY (
					p_runtime_user => '${ords_user}',
					p_plsql_gateway_user => '${ords_plgw}'
				);
			END;
			/"

		run_sql "${_PASS}" "${_DBNAME}" "${_GATEWAY_SQL}"
	fi

	return ${_RC}
}

function set_image_cdn {
	typeset -i _RC=0
	typeset -r _PASS=$1
	typeset -r _DBNAME=$2
	typeset -r _VERSION=$3

	typeset -r _SQL="
	    begin
    	    apex_instance_admin.set_parameter(
        	    p_parameter => 'IMAGE_PREFIX',
        	    p_value     => 'https://static.oracle.com/cdn/apex/${_VERSION}/' );
        	commit;
    	end;
		/"

	run_sql "${_PASS}" "${_DBNAME}" "${_SQL}"
	_RC=$?

	return ${_RC}
}

function write_apex_pu {
	typeset -i _RC=0
	typeset -r _FILE="apex_pu.xml"
	typeset -r _DIR=$1
	typeset -r _PASS=$2
	typeset -r _DBNAME=$3
	typeset -r _WALLET_FILE=$4

	typeset -r _WALLET=$(cat ${_WALLET_FILE})

	mkdir -p ${_DIR}
	cat > ${_DIR}/${_FILE} <<- EOF
		<?xml version="1.0" encoding="UTF-8" standalone="no"?>
		<!DOCTYPE properties SYSTEM "http://java.sun.com/dtd/properties.dtd">
		<properties>
		<entry key="db.username">${ords_user}</entry>
		<entry key="db.password">!${_PASS}</entry>
		<entry key="db.wallet.zip.service">${_DBNAME}_TP</entry>
		<entry key="db.wallet.zip"><![CDATA[${_WALLET}]]></entry>
		</properties>
	EOF
	if [[ ! -f ${_DIR}/${_FILE} ]]; then
		echo "ERROR: Unable to write ${_DIR}/${_FILE}"
		_RC=1
	else
		echo "Wrote ${_DIR}/${_FILE}"
	fi
	return ${_RC}
}

function write_defaults {
	typeset -i _RC=0
	typeset -r _FILE="defaults.xml"
	typeset -r _DIR=$1

	mkdir -p ${_DIR}
	cat > ${_DIR}/${_FILE} <<- EOF
		<?xml version="1.0" encoding="UTF-8" standalone="no"?>
		<!DOCTYPE properties SYSTEM "http://java.sun.com/dtd/properties.dtd">
		<properties>
		<entry key="plsql.gateway.enabled">true</entry>
		<entry key="jdbc.InitialLimit">10</entry>
		<entry key="jdbc.MaxLimit">20</entry>
    <entry key="jdbc.enableONS">false</entry>
		<entry key="feature.sdw">false</entry>
		<entry key="restEnabledSql.active">true</entry>
		<entry key="database.api.enabled">false</entry>
		<entry key="misc.defaultPage">f?p=DEFAULT</entry>
		</properties>
	EOF
	if [[ ! -f ${_DIR}/${_FILE} ]]; then
		echo "ERROR: Unable to write ${_DIR}/${_FILE}"
		_RC=1
	else
		echo "Wrote ${_DIR}/${_FILE}"
	fi
	return ${_RC}
}

function write_standalone_properties {
	typeset -i _RC=0
	typeset -r _FILE="standalone.properties"
	typeset -r _DIR=$1
	typeset -r _APEX_VERSION=$2
	typeset -r _CONTEXT=$3
	typeset -r _STANDALONE_ROOT=$4

	mkdir -p ${_DIR}
	cat > ${_DIR}/${_FILE} <<- EOF
		jetty.port=8080
		standalone.context.path=/${_CONTEXT}
		standalone.doc.root=${_STANDALONE_ROOT}
		standalone.scheme.do.not.prompt=true
		standalone.static.context.path=/i
	EOF
	return ${_RC}
}

function copy_app {
	typeset -i _RC=0
	typeset -r _DIR=$1

	#Ensure the webroot exists for CertBot/LetsEncrypt purposes
	#Add a redirect index to the DEFAULT application
	mkdir -p ${_DIR}

	cp -r /tmp/uploads/web/* ${_DIR}

	return ${_RC}
}

#------------------------------------------------------------------------------
# INIT
#------------------------------------------------------------------------------
if [[ $(whoami) != "oracle" ]]; then
	usage && exit 1
fi

while getopts :t:p:v:h args; do
	case $args in
		t) typeset -r  db_name=${OPTARG} ;;
		p) typeset -r  admin_password=${OPTARG} ;;
		v) typeset -r  apex_version=${OPTARG} ;;
		h) usage ;;
	esac
done

if [[ -z ${db_name} || -z ${admin_password} || -z ${apex_version} ]]; then
	usage && exit 1
fi

if [[ ! -d ${ords_dir} ]]; then
	echo "ERROR: Cannot find ${ords_dir}; is ords installed?" && exit 1
fi
#------------------------------------------------------------------------------
# main
#------------------------------------------------------------------------------

# setup the tns_admin
export TNS_ADMIN=~/tns_admin
mkdir -p $TNS_ADMIN
cp ${script_dir}/adb_wallet.zip $TNS_ADMIN/
unzip -o ${script_dir}/adb_wallet.zip -d ${TNS_ADMIN}
base64 -w 0 ${script_dir}/adb_wallet.zip > $TNS_ADMIN/adb_wallet.zip.b64
cat >$TNS_ADMIN/sqlnet.ora <<- !
	WALLET_LOCATION = (SOURCE = (METHOD = file) (METHOD_DATA = (DIRECTORY="$TNS_ADMIN")))
	SSL_SERVER_DN_MATCH=yes
!

grabdish_db_setup "${admin_password}" "${db_name}_TP" 'classicq'
RC=$?

config_user "${admin_password}" "${db_name}"
RC=$?

set_image_cdn "${admin_password}" "${db_name}" "${apex_version}"
RC=$(( RC + $? ))

write_apex_pu "${ords_dir}/config/ords/conf" "${admin_password}" "${db_name}" "$TNS_ADMIN/adb_wallet.zip.b64"
RC=$(( RC + $? ))

write_defaults "${ords_dir}/config/ords"
RC=$(( RC + $? ))

standalone_root="${ords_dir}/config/ords/standalone/web"

write_standalone_properties "${ords_dir}/config/ords/standalone" "${apex_version}" 'ords' "${standalone_root}"
RC=$(( RC + $? ))

copy_app "${standalone_root}"

# Debugging Startup
cat > /opt/oracle/ords/mylogfile.properties <<'!'
handlers=java.util.logging.FileHandler
# Default global logging level for ORDS
#.level=CONFIG
.level=FINE
java.util.logging.FileHandler.pattern=/var/log/ords/ords-sys.log
java.util.logging.FileHandler.formatter = java.util.logging.SimpleFormatter
java.util.logging.SimpleFormatter.format = %1$tY-%1$tm-%1$td %1$tH:%1$tM:%1$tS %4$-6s %2$s %5$s%6$s%n
!

cat >/etc/ords/ords.conf <<'!'
ORDS_CONFIGDIR=/opt/oracle/ords/config
JAVA_HOME=/usr/java/latest
JAVA_OPTIONS=-Djava.util.logging.config.file=mylogfile.properties -Xmx2048m
ORDS_BASE_PATH=/opt/oracle
!

echo "FINISHED: Return Code: ${RC}"
exit $RC
