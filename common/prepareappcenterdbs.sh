#   Licensed Materials - Property of IBM
#   5725-I43 (C) Copyright IBM Corp. 2011, 2015. All Rights Reserved.
#   US Government Users Restricted Rights - Use, duplication or
#   disclosure restricted by GSA ADP Schedule Contract with IBM Corp.

#!/usr/bin/bash

usage()
{
   echo
   echo " Configuring the database service on Bluemix for use by MobileFirst Application Center Image "
   echo " ------------------------------------------------------------------------------------------- "
   echo " Use this script to configure MobileFirst Platform Application Center databases"
   echo
   echo " Silent Execution (arguments provided as command line arguments):"
   echo "   USAGE: prepareappcenterdbs.sh <command line arguments> "
   echo "   command-line arguments: "
   echo "     -db | --acdb APPCENTER_DB_SRV_NAME       Bluemix DB service instance name for storing application center data"
   echo "     -ds | --acds APPCENTER_SCHEMA_NAME   (Optional) Database schema name for Application Center (defaults to APPCNTR) "
   echo " Silent Execution (arguments loaded from file):"
   echo "   USAGE: prepareappcenterdbs.sh <path to the file from which arguments are read>"
   echo "          See args/prepareappcenterdbs.properties for the list of arguments."
   echo
   echo " Interactive Execution: "
   echo "   USAGE: prepareappcenterdbs.sh"
   echo
   echo " Get a verbose output by setting the environment variable VERBOSE to true "
   echo " export VERBOSE=true"
   echo " Redirect the verbose output to a file with setting the environment variable to the full-path filename of the log file to be created"
   echo " export VERBOSE=/tmp/prepareappcenterdbs.log"
   echo
   echo
   exit 1
}

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

validateDbPlan()
{
        export SERVICE_TYPE=$(cf service $1 | grep "Service:" | cut -d" " -f2)
        export SERVICE_PLAN=$(cf service $1 | grep "Plan:" | cut -d" " -f2)

        if [[ "${SERVICE_TYPE}" = "" ]]
        then
                echo "Error occurred. The service $1 does not exist in the current users organization/space."
                exit 1;
        fi
        if [[ "${SERVICE_TYPE}" != "dashDB" ]]
        then
                echo "Error occurred. The service $1 is an instance of ${SERVICE_TYPE}. This is not a recognized service."
                exit 1;
        fi


        if [[ "${SERVICE_TYPE}" = "dashDB" ]]
	    then
	        echo "${SERVICE_PLAN}" | grep "Transactional" >/dev/null 2>&1
	        RET_VAL=$?
	        if (( ${RET_VAL} != 0 ))
	        then
	        	echo "${SERVICE_PLAN}" | grep "Entry" >/dev/null 2>&1
	        	RET_VAL=$?
	        		if (( ${RET_VAL} != 0 ))
	        		then
                        	echo "Error occurred. The service plan ${SERVICE_PLAN} for the service ${1} is not recognized. Select a service instance with Transactinal plan for the dashDB service"
                        exit 1;
                    else
                    	export SERVICE_PLAN="Entry"
                    fi
	        else
		        export SERVICE_PLAN="Transactional"
	        fi
        fi

	echo ${SERVICE_PLAN}
}

# getServiceKey service-name
getServiceKey()
{
        export CF_OUTPUT=$(cf service-keys $1)
        export CF_SERVICE_KEY_NAME=$(echo $CF_OUTPUT | cut -d" " -f9)
        if [ "name" = "$CF_SERVICE_KEY_NAME" ]
        then
                export CF_SERVICE_KEY=$(echo $CF_OUTPUT | cut -d" " -f10)
        elif [ "No" = "$CF_SERVICE_KEY_NAME" ]
        then
                export CF_SERVICE_KEY=no_key_found
        else
                export CF_SERVICE_KEY=no_service_found
        fi
        echo $CF_SERVICE_KEY
}

# createServiceKey service-name - creates a key with the same name as the service
createServiceKey()
{
       cf create-service-key $1 $1
       if (( $? != 0 ))
       then
               echo "Error occurred. Could not create a service key."
               exit 1
       fi
}

configureSqldb()
{
	if [[ "${APPCNTR_DB_SERVICE_PLAN}" = "Transactional" ]]
	then
        createSqldbSchema $APPCENTER_DB_SRV_NAME databases $APPCENTER_SCHEMA_NAME
	else
		createSqldbSchema $APPCENTER_DB_SRV_NAME databases
	fi
	mv ../usr/env/server.env ../usr/env/server.env.backup
	cat ../usr/env/server.env.backup | grep -Ev "APPCNTR_DB2_SERVER_NAME=|APPCNTR_DB2_PORT=|APPCNTR_DB2_DATABASE_NAME=|APPCNTR_DB2_USERNAME=|APPCNTR_DB2_PASSWORD=|APPCNTR_DB2_SCHEMA=|SSL_CONNECTION=" > ../usr/env/server.env
	rm ../usr/env/server.env.backup
        echo "" >> ../usr/env/server.env
        echo APPCNTR_DB2_SERVER_NAME=$(getSqldbHost) >> ../usr/env/server.env
        echo APPCNTR_DB2_PORT=$(getSqldbPort) >> ../usr/env/server.env
        echo APPCNTR_DB2_DATABASE_NAME=$(getSqldbName) >> ../usr/env/server.env
        echo APPCNTR_DB2_USERNAME=$(getSqldbUsername) >> ../usr/env/server.env
        echo APPCNTR_DB2_PASSWORD=$(getSqldbPassword) >> ../usr/env/server.env
        echo APPCNTR_DB2_SCHEMA=$APPCENTER_SCHEMA_NAME >> ../usr/env/server.env
        echo SSL_CONNECTION=true >> ../usr/env/server.env

	mv ../usr/config/appcentersqldb.xml ../usr/config/appcentersqldb.xml-moved
	cat ../usr/config/appcentersqldb.xml-moved | grep -v "AUTO GENERATED LINE by prepareappcenterdbs.sh. DO NOT EDIT" > ../usr/config/appcentersqldb.xml
	rm ../usr/config/appcentersqldb.xml-moved

    echo "" >> ../usr/env/server.env

}

createSqldbSchema()
{
        export CURRENT_SERVICE_KEY=$(getServiceKey $1)
        if [ "${CURRENT_SERVICE_KEY}" = "no_service_found" ]
        then
                echo "Error occurred. The service by name $1 was not found in the current organization/space."
                exit 1
        elif [ "${CURRENT_SERVICE_KEY}" = "no_key_found" ]
        then
                echo "The service $1 does not have a service key. Creating a service key.."
                createServiceKey $1
                export CURRENT_SERVICE_KEY=$(getServiceKey $1)
        fi
        setSqldbCredentials $1 $CURRENT_SERVICE_KEY
        export ANT_OUTPUT=$(ant -f ../../common/create-appcenter-database-db2.xml -Ddatabase.db2.admin.password=$(getSqldbPassword) -Ddatabase.db2.appcenter.password=$(getSqldbPassword) -Dmfp.server.install.dir="../" -Ddatabase.db2.host=$(getSqldbHost) -Ddatabase.db2.port=$(getSqldbConfigPort) -Ddatabase.db2.admin.username=$(getSqldbUsername) -Ddatabase.db2.appcenter.schema=$APPCENTER_SCHEMA_NAME -Ddatabase.db2.appcenter.username=$(getSqldbUsername) -Ddatabase.db2.appcenter.dbname=$(getSqldbName) -Ddatabase.db2.instance=SQLDB $2)

        echo ${ANT_OUTPUT}  | grep "BUILD SUCCESSFUL" >/dev/null
	if (( $? != 0 ))
        then
                echo "Error occurred while running ant scripts to create Database schema/tables. Creation of the schema/tables on the database failed."
                exit 1
        fi
}

# setSqldbCredentials service-name service-key
setSqldbCredentials()
{
	eval $( cf service-key "$1" "$2" |  sed 's/[, ]//g' | awk -F":" '{
								     if ($1 ~ /"ssldsn"/) {
									     print "export SSLDSN="$2;
								     } else if ($1 ~ /"port"/) {
								             print "export DB_CONFIG_PORT="$2;
								     }

							     }' )
        eval $( echo $SSLDSN | awk -F";" '{
                                              for( i=1; i <= NF ; i++) {
                                                 print "export DB_"$i; 
                                              }
                                          }')
                                          
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

getSqldbPort()
{
        echo $DB_PORT
}

getSqldbConfigPort()
{
        echo $DB_CONFIG_PORT
}

getSqldbUsername()
{
        echo $DB_UID
}

readParams()
{

    export INTERACTIVE_MODE=true

    # Read the IBM Bluemix Database Service Name for Application Center data
    #-----------------------------------------------------------------------
    INPUT_MSG="Specify the name of your Bluemix database service for storing application center data. (mandatory) : "
    ERROR_MSG="Bluemix Database Service Name cannot be empty. Specify the name of your Bluemix database service for storing application center data. (mandatory) : "
    APPCENTER_DB_SRV_NAME=$(fnReadInput "$INPUT_MSG" "$ERROR_MSG")

	# Generate VCAP and validate the service plan from the vcap
    #--------------------------------------------------------
	APPCENTER_DB_SERVICE_PLAN=$(validateDbPlan ${APPCENTER_DB_SRV_NAME})
        RET_VAL=$?
        if (( ${RET_VAL} != 0 ))
        then
                echo ${APPCENTER_DB_SERVICE_PLAN}
                exit ${RET_VAL}
        fi

        # Read the Database Schema Name
        #------------------------------
        if [[ "${APPCENTER_DB_SERVICE_PLAN}" = "Transactional" ]]
        then
        	read -p "Specify the name of the database schema for application center (defaults to APPCNTR) (optional) : " APPCENTER_SCHEMA_NAME
        fi

}

validateParams()
{
	if [ -z "$APPCENTER_DB_SRV_NAME" ]
	then
    	        echo IBM Bluemix Database Service Name field for Application Center is empty. A mandatory argument must be specified. Exiting...
		exit 0
	fi
   	if [ -z "$APPCENTER_SCHEMA_NAME" ]
   	then
   		APPCENTER_SCHEMA_NAME=APPCNTR
   	fi
}

#main

export PATH=$PATH:../../mfpf-libs/apache-ant-1.9.4/bin

debug "==========================================================================="
debug prepareserverdbs.sh start: $(date)
debug "==========================================================================="
cd "$( dirname "$0" )"

# check if user has overridden JAVA_HOME .
if [ -z "$JAVA_HOME" ]
then
   echo "JAVA_HOME is not set. Please set JAVA_HOME and retry."
   exit 1
fi
export PATH=$JAVA_HOME/bin:$PATH


if [ $# == 0 ]
then
   readParams
elif [ "$#" -eq 1 -a -f "$1" ]
then
   source "$1"

elif [ "$1" = "-h" -o "$1" = "--help" ]
then
   usage
else
   while [ $# -gt 0 ]; do
      case "$1" in
         -db | --acdb)
            APPCENTER_DB_SRV_NAME="$2";
            shift
            ;;
         -ds | --acds)
            APPCENTER_SCHEMA_NAME="$2";
            shift
            ;;
         *)
            usage
            ;;
      esac
      shift
   done
fi

trap - SIGINT

validateParams

if [ "${INTERACTIVE_MODE}" != "true" ]
then
   # Generate VCAP
   #--------------------
   APPCENTER_DB_SERVICE_PLAN=$(validateDbPlan ${APPCENTER_DB_SRV_NAME})
   RET_VAL=$?
   if (( ${RET_VAL} != 0 ))
   then
      echo ${APPCENTER_DB_SERVICE_PLAN}
      exit ${RET_VAL}
   fi
fi


output "Arguments : "
output "----------- "
output
output "APPCENTER_DB_SRV_NAME    : " $APPCENTER_DB_SRV_NAME
if [[ "${APPCENTER_DB_SERVICE_PLAN}" = "Transactional" ]]
then
	output "APPCENTER_SCHEMA_NAME   : " $APPCENTER_SCHEMA_NAME
fi

debug
debug "JAVA_HOME:" $JAVA_HOME
debug " "

configureSqldb

output
output The command prepareappcenterdbs.sh completed successfully.
output
debug "==========================================================================="
debug prepareserverdbs.sh end: $(date)
debug "==========================================================================="
