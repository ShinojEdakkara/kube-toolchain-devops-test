###############################################################################
# Licensed Materials - Property of IBM 
# 5725-I43 (C) Copyright IBM Corp 2018. All Rights Reserved.
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
###############################################################################

#!/usr/bin/bash
cd "$( dirname "$0" )"

debug()
{
        if [ "${VERBOSE}" = "true" ]
        then
                echo $*
        elif [ ! -z "${VERBOSE}" ]
        then
                touch ${VERBOSE}
                if (( $? != 0 ))
                then
                        echo "Unable to write to file ${VERBOSE}. Make sure that you have set the variable to a valid file location and it is writable."
                        exit 1
                else
                        echo $* >> ${DEBUG}
                fi
        fi
}

output()
{
        echo $*
        if [[ ! -z ${DEBUG} && "${DEBUG}" != "true" ]]
	then
                debug $*
        fi
}

envSource()
{
  if [ -d /opt/ibm/MobileFirst/envs ]
  then
    for customEnvDirectory in `ls /opt/ibm/MobileFirst/envs`
    do
        if [ -d /opt/ibm/MobileFirst/envs/${customEnvDirectory} ]
        then
             for customEnvFile in `ls /opt/ibm/MobileFirst/envs/${customEnvDirectory}`
             do
                 source /opt/ibm/MobileFirst/envs/${customEnvDirectory}/$customEnvFile
             done
        else
            source /opt/ibm/MobileFirst/envs/${customEnvDirectory}
        fi
    done
  fi
}


configureSqldb()
{
	if [[ "${DB_TYPE}" = "DB2" ]]
	then
                createSqldbSchema DB2 admdatabases "${MFPF_ADMIN_DB2_SCHEMA}"
	fi

	if [[ "${DB_TYPE}" = "DB2" ]]
	then
                createSqldbSchema DB2 rtmdatabases "${MFPF_RUNTIME_DB2_SCHEMA}"
	fi

        if [ "$ENABLE_PUSH" = "Y" ]
        then
	        if [[ "${DB_TYPE}" = "DB2" ]]
	        then
	                createSqldbSchema DB2 pushdatabases "${MFPF_PUSH_DB2_SCHEMA}"
	        fi
        fi

        
}

createSqldbSchema()
{
        if [[ "${DB_TYPE}" = "DB2" ]]
        then
                setDB2Credentials

        fi

	if [ -z "$3" ]
	then
                export ANT_OUTPUT=$(ant -f ./create-database-db2.xml -Ddatabase.db2.admin.password=$(getSqldbPassword) -Ddatabase.db2.mfp.password=$(getSqldbPassword) -Dmfp.server.install.dir="./" -Ddatabase.db2.host=$(getSqldbHost) -Ddatabase.db2.port=$(getSqldbConfigPort) -Ddatabase.db2.admin.username=$(getSqldbUsername) -Ddatabase.db2.mfp.schema="" -Ddatabase.db2.mfp.username=$(getSqldbUsername) -Ddatabase.db2.mfp.dbname=$(getSqldbName) -Ddatabase.db2.instance=SQLDB $2 2>&1 )
	else
                export ANT_OUTPUT=$(ant -f ./create-database-db2.xml -Ddatabase.db2.admin.password=$(getSqldbPassword) -Ddatabase.db2.mfp.password=$(getSqldbPassword) -Dmfp.server.install.dir="./" -Ddatabase.db2.host=$(getSqldbHost) -Ddatabase.db2.port=$(getSqldbConfigPort) -Ddatabase.db2.admin.username=$(getSqldbUsername) -Ddatabase.db2.mfp.schema="$3" -Ddatabase.db2.mfp.username=$(getSqldbUsername) -Ddatabase.db2.mfp.dbname=$(getSqldbName) -Ddatabase.db2.instance=SQLDB $2 2>&1 )
	fi

        echo ${ANT_OUTPUT}  | grep "BUILD SUCCESSFUL" >/dev/null 
	if (( $? != 0 ))
        then
                echo "Error occurred while running ant scripts to create Database schema/tables. Creation of the schema/tables on the database failed."
                echo ${ANT_OUTPUT}
                exit 1
        fi
}

# setSqldbCredentials service-name service-key

setDB2Credentials()
{
        export DB_DATABASE=${MFPF_ADMIN_DB2_DATABASE_NAME}
        export DB_HOSTNAME=${MFPF_ADMIN_DB2_SERVER_NAME}
        export DB_PWD=${MFPF_ADMIN_DB2_PASSWORD}
        export DB_PORT=${MFPF_ADMIN_DB2_PORT}
        export DB_CONFIG_PORT=${MFPF_ADMIN_DB2_PORT}
        export DB_UID=${MFPF_ADMIN_DB2_USERNAME}
}

getSqldbName()
{
        echo $DB_DATABASE
}

getSqldbHost()
{
        echo $DB_HOSTNAME
}

getSqldbPassword()
{
        echo $DB_PWD
}

getSqldbConfigPort()
{
        echo $DB_CONFIG_PORT
}

getSqldbPort()
{
        echo $DB_PORT
}

getSqldbUsername()
{
        echo $DB_UID
}


validateParams() 
{
	if [ -z "${DB_TYPE}" ]
	then
    	        echo The DB_TYPE value is empty. A mandatory argument must be specified. Valid options are DB2 or dashDB Exiting...
		exit 1
	fi
        if [ "${DB_TYPE}" = "DB2" ]
        then
	        if [ -z "${MFPF_ADMIN_DB2_SERVER_NAME}" ]
	        then
    	                echo The hostname for the DB2 database is empty. A mandatory argument must be specified. Exiting...
		        exit 1
	        fi
	        if [ -z "${MFPF_ADMIN_DB2_DATABASE_NAME}" ]
	        then
    	                echo The database name for the DB2 database is empty. A mandatory argument must be specified. Exiting...
		        exit 1
	        fi
	        if [ -z "${MFPF_ADMIN_DB2_PORT}" ]
	        then
    	                export DB2_PORT=50000
	        fi
	        if [ -z "${MFPF_ADMIN_DB2_USERNAME}" ]
	        then
    	                echo The username for the DB2 database is empty. A mandatory argument must be specified. Exiting...
		        exit 1
	        fi
	        if [ -z "${MFPF_ADMIN_DB2_PASSWORD}" ]
	        then
    	                echo The password for the DB2 database is empty. A mandatory argument must be specified. Exiting...
		        exit 1
	        fi
        fi
        if [ "${DB_TYPE}" = "dashDB" ]
        then
	        if [ -z "$ADMIN_DB_SRV_NAME" ]
	        then
    	                echo IBM Bluemix Database Service Name field for admin service is empty. A mandatory argument must be specified. Exiting...
		        exit 1
	        fi
        fi
   	if [ -z "$MFPF_ADMIN_DB2_SCHEMA" ]
   	then
   		MFPF_ADMIN_DB2_SCHEMA=MFPDATA
   	fi
        export MFPF_ADMIN_DB2_SCHEMA=$(echo $MFPF_ADMIN_DB2_SCHEMA | tr '[:lower:]' '[:upper:]')

	if [ -z "$RUNTIME_DB_SRV_NAME" ]
	then
    	        RUNTIME_DB_SRV_NAME="${ADMIN_DB_SRV_NAME}"
	fi
   	if [ -z "$MFPF_RUNTIME_DB2_SCHEMA" ]
   	then
   		MFPF_RUNTIME_DB2_SCHEMA=${MFPF_ADMIN_DB2_SCHEMA}
   	fi
        export MFPF_RUNTIME_DB2_SCHEMA=$(echo $MFPF_RUNTIME_DB2_SCHEMA | tr '[:lower:]' '[:upper:]')
 
        if [ -z "$ENABLE_PUSH" ]
        then
                ENABLE_PUSH=Y
        fi
	if [ -z "$PUSH_DB_SRV_NAME" ]
	then
    	        PUSH_DB_SRV_NAME="${RUNTIME_DB_SRV_NAME}"
	fi
   	if [ -z "$MFPF_PUSH_DB2_SCHEMA" ]
   	then
   		MFPF_PUSH_DB2_SCHEMA=${MFPF_RUNTIME_DB2_SCHEMA}
   	fi
        export MFPF_PUSH_DB2_SCHEMA=$(echo $MFPF_PUSH_DB2_SCHEMA | tr '[:lower:]' '[:upper:]')
}

#main

debug "==========================================================================="
debug prepareserverdbs.sh start: $(date)
debug "==========================================================================="


export PATH=$PATH:/opt/ibm/MobileFirst/apache-ant-1.9.4/bin



# check if user has overridden JAVA_HOME . 
if [ -z "$JAVA_HOME" ]
then
   echo "JAVA_HOME is not set. Please set JAVA_HOME and retry."
   exit 1
fi
export PATH=$JAVA_HOME/bin:$PATH
envSource
#Hardcode DB_TYPE to DB2 for now
export DB_TYPE="DB2"

if [ "$#" -eq 1 -a -f "$1" ]
then
   source "$1"

elif [ "$1" = "-h" -o "$1" = "--help" ]
then
   exit 1
fi

trap - SIGINT

validateParams

output "Arguments : "
output "----------- "
output
output "DB_TYPE              : " $DB_TYPE
if [[ "${DB_TYPE}" = "DB2" ]]
then
        output "DB2_HOST              : " $MFPF_ADMIN_DB2_SERVER_NAME
        output "DB2_DATABASE          : " $MFPF_ADMIN_DB2_DATABASE_NAME
        output "DB2_PORT              : " $MFPF_ADMIN_DB2_PORT
        output "DB2_USERNAME          : " $MFPF_ADMIN_DB2_USERNAME
        output "DB2_PASSWORD          : " XXXXXXXX
fi
if [[ "${DB_TYPE}" = "dashDB" ]]
then
        output "ADMIN_DB_SRV_NAME    : " $ADMIN_DB_SRV_NAME
fi
if [[ "${DB_TYPE}" = "DB2" ]] || [[ "${ADMIN_SERVICE_PLAN}" = "Transactional" ]]
then
	output "MFPF_ADMIN_DB2_SCHEMA   : " $MFPF_ADMIN_DB2_SCHEMA
fi
if [[ "${DB_TYPE}" = "dashDB" ]]
then
        output "RUNTIME_DB_SRV_NAME    : " $RUNTIME_DB_SRV_NAME
fi
if [[ "${DB_TYPE}" = "DB2" ]] || [[ "${RUNTIME_SERVICE_PLAN}" = "Transactional" ]]
then
	output "MFPF_RUNTIME_DB2_SCHEMA : " $MFPF_RUNTIME_DB2_SCHEMA
fi
output "ENABLE_PUSH    : " $ENABLE_PUSH
if [[ "${ENABLE_PUSH}" = "Y" ]]
then
        if [[ "${DB_TYPE}" = "dashDB" ]]
        then
        	output "PUSH_DB_SRV_NAME    : " $PUSH_DB_SRV_NAME
        fi
	if [[ "${DB_TYPE}" = "DB2" ]] || [[ "${PUSH_SERVICE_PLAN}" = "Transactional" ]]
	then
		output "MFPF_PUSH_DB2_SCHEMA    : " $MFPF_PUSH_DB2_SCHEMA
	fi
fi

debug
debug "JAVA_HOME:" $JAVA_HOME
debug " "

configureSqldb

output
output The command prepareserverdbs.sh completed successfully.
output
debug "==========================================================================="
debug prepareserverdbs.sh end: $(date)
debug "==========================================================================="
