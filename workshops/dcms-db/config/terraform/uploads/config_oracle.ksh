#!/usr/bin/env ksh
#------------------------------------------------------------------------------
# GLOBAL/DEFAULT VARS
#------------------------------------------------------------------------------
typeset -i  RC=0
typeset -r  IFS_ORIG=$IFS
typeset -rx SCRIPT_NAME="${0##*/}"
typeset -rx SCRIPTDIR="/tmp/uploads"

typeset -r ORDS_DIR="/opt/oracle/ords"
typeset -r CONTEXT="ords"
typeset -r ORDS_USER="ORDS_PUBLIC_USER_OCI"
typeset -r ORDS_PLGW="ORDS_PLSQL_GATEWAY_OCI"

#------------------------------------------------------------------------------
# LOCAL FUNCTIONS
#------------------------------------------------------------------------------
function usage {
	print -- "${SCRIPT_NAME} Usage"
	print -- "${SCRIPT_NAME} MUST be run by oracle"
	print -- "\t\t${SCRIPT_NAME} -t <DB_NAME> -p <ADMIN_PASS> -v <APEX_VERSION> [-h]"
	return 0
}

function run_sql {
	typeset -i _RC=0
	typeset -r _PASS=$1
	typeset -r _DBNAME=$2
	typeset -r _SQL=$3

	print "Connnecting to ${_DBNAME}_TP (TNS_ADMIN=$TNS_ADMIN)"
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

	create_user "${_PASS}" "${_DBNAME}" "${ORDS_USER}"
	_RC=$?

	create_user "${_PASS}" "${_DBNAME}" "${ORDS_PLGW}"
	_RC=$(( _RC + $? ))

	if (( _RC == 0 )); then
		typeset -r _PUBLIC_SQL="
			BEGIN
				DBMS_OUTPUT.PUT_LINE('Giving ${ORDS_USER} the Runtime Role');
				ORDS_ADMIN.PROVISION_RUNTIME_ROLE (
					p_user => '${ORDS_USER}',
					p_proxy_enabled_schemas => TRUE
				);
			END;
			/"

		run_sql "${_PASS}" "${_DBNAME}" "${_PUBLIC_SQL}"

		typeset -r _GATEWAY_SQL="
			ALTER USER ${ORDS_PLGW} GRANT CONNECT THROUGH ${ORDS_USER};
			BEGIN
				ORDS_ADMIN.CONFIG_PLSQL_GATEWAY (
					p_runtime_user => '${ORDS_USER}',
					p_plsql_gateway_user => '${ORDS_PLGW}'
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
		<entry key="db.username">${ORDS_USER}</entry>
		<entry key="db.password">!${_PASS}</entry>
		<entry key="db.wallet.zip.service">${_DBNAME}_TP</entry>
		<entry key="db.wallet.zip"><![CDATA[${_WALLET}]]></entry>
		</properties>
	EOF
	if [[ ! -f ${_DIR}/${_FILE} ]]; then
		print -- "ERROR: Unable to write ${_DIR}/${_FILE}"
		_RC=1
	else
		print -- "Wrote ${_DIR}/${_FILE}"
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
		<entry key="jdbc.MaxLimit">1200</entry>
		<entry key="security.httpsHeaderCheck">X-Forwarded-Proto: https</entry>
		<entry key="feature.sdw">false</entry>
		<entry key="restEnabledSql.active">true</entry>
		<entry key="database.api.enabled">false</entry>
		<entry key="misc.defaultPage">f?p=DEFAULT</entry>
		</properties>
	EOF
	if [[ ! -f ${_DIR}/${_FILE} ]]; then
		print -- "ERROR: Unable to write ${_DIR}/${_FILE}"
		_RC=1
	else
		print -- "Wrote ${_DIR}/${_FILE}"
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

function write_index {
	typeset -i _RC=0
	typeset -r _FILE="index.html"
	typeset -r _DIR=$1

	#Ensure the webroot exists for CertBot/LetsEncrypt purposes
	#Add a redirect index to the DEFAULT application
	mkdir -p ${_DIR}

	cat > ${_DIR}/${_FILE} <<- EOF
		<!DOCTYPE HTML>
		<meta charset="UTF-8">
		<meta http-equiv="refresh" content="1; url=./ords/f?p=DEFAULT">
		<script>
		window.location.href = "./ords/f?p=DEFAULT"
		</script>
		<title>Page Redirection</title>
		If you are not redirected automatically, follow this <a href='./ords/f?p=DEFAULT"'>link</a>
	EOF
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
		t) typeset -r  MYTARGET=${OPTARG} ;;
		p) typeset -r  MYPASSWORD=${OPTARG} ;;
		v) typeset -r  MYAPEX_VERSION=${OPTARG} ;;
		h) usage ;;
	esac
done

if [[ -z ${MYTARGET} || -z ${MYPASSWORD} || -z ${MYAPEX_VERSION} ]]; then
	usage && exit 1
fi

if [[ ! -d ${ORDS_DIR} ]]; then
	print -- "ERROR: Cannot find ${ORDS_DIR}; is ords installed?" && exit 1
fi
typeset -r STANDALONE_ROOT="${ORDS_DIR}/config/${CONTEXT}/standalone/doc_root"
#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------
export ORACLE_HOME=${HOME}
print -- "Set ORACLE_HOME=$ORACLE_HOME"
export TNS_ADMIN=$ORACLE_HOME/network/admin
print -- "Setting up $TNS_ADMIN"

mkdir -p $TNS_ADMIN
cp ${SCRIPTDIR}/adb_wallet.zip $TNS_ADMIN/
base64 -w 0 $TNS_ADMIN/adb_wallet.zip > $TNS_ADMIN/adb_wallet.zip.b64
unzip -o ${TNS_ADMIN}/adb_wallet.zip -d ${TNS_ADMIN}

config_user "${MYPASSWORD}" "${MYTARGET}"
RC=$?

set_image_cdn "${MYPASSWORD}" "${MYTARGET}" "${MYAPEX_VERSION}"
RC=$(( RC + $? ))

write_apex_pu "${ORDS_DIR}/config/${CONTEXT}/conf" "${MYPASSWORD}" "${MYTARGET}" "$TNS_ADMIN/adb_wallet.zip.b64"
RC=$(( RC + $? ))

write_defaults "${ORDS_DIR}/config/${CONTEXT}" 
RC=$(( RC + $? ))

write_standalone_properties "${ORDS_DIR}/config/${CONTEXT}/standalone" "${MYAPEX_VERSION}" "${CONTEXT}" "${STANDALONE_ROOT}"
RC=$(( RC + $? ))

write_index "${STANDALONE_ROOT}"

print -- "FINISHED: Return Code: ${RC}"
exit $RC