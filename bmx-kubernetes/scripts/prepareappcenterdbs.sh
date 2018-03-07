#   Licensed Materials - Property of IBM
#   5725-I43 (C) Copyright IBM Corp. 2011, 2015. All Rights Reserved.
#   US Government Users Restricted Rights - Use, duplication or
#   disclosure restricted by GSA ADP Schedule Contract with IBM Corp.

#!/usr/bin/bash
cd "$( dirname "$0" )"
source ../../common/common.sh
export CUSTOMIZATION_DIR=usr-mfp-appcenter

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
   echo "     -t  | --type DB_TYPE                    Database Type. (DB2 | dashDB)"
   echo "     -h  | --host DB2_HOST                   Hostname or IP where DB2 database is configured. Mandatory if DB_TYPE=DB2."
   echo "     -d  | --database DB2_DATABASE           Database Name on DB2. Mandatory if DB_TYPE=DB2. "
   echo "     -r  | --port DB2_PORT                   Port on which the DB2 database is configured. Mandatory if DB_TYPE=DB2. (Defaults to 50000)"
   echo "     -u  | --username DB2_USERNAME           Username to access the DB2 database. Mandatory if DB_TYPE=DB2."
   echo "     -pw | --password DB2_PASSWORD           Password for the DB2 database. Mandatory if DB_TYPE=DB2."
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
        export DASHDB_FLAG="false"
        while read oneLine
        do
                serviceName=`echo "${oneLine}" | cut -d'#' -f1`
                serviceType=`echo "${oneLine}" | cut -d'#' -f2`
                servicePlan=`echo "${oneLine}" | cut -d'#' -f3`
                if [[ "$1" = "${serviceName}" ]]
                then
                        export SERVICE_TYPE=${serviceType};
                        export SERVICE_PLAN=${servicePlan};
                        if [[ "${serviceType}" = "dashDB" ]] || [[ "${serviceType}" = "dashDB For Transactions" ]]
                        then
                                export DASHDB_FLAG="true";
                                break;
                        else
                                echo "Error occurred. The service $1 is an instance of ${SERVICE_TYPE}. This is not a recognized service."
                                exit 1;
                        fi
                fi
        done <<EOF
        $(bx service list | sed 's/   */#/g')
EOF
        if [[ "${SERVICE_TYPE}" = "" ]]
        then
                echo "Error occurred. The service $1 does not exist in the current users organization/space."
                exit 1;
        fi

        echo "${SERVICE_PLAN}" | grep "Transaction" >/dev/null 2>&1
        RET_VAL=$?
        if (( ${RET_VAL} != 0 ))
        then
                echo "Error occurred. The service plan ${SERVICE_PLAN} for the service ${1} is not supported. Select a service instance with Transactinal plan for the dashDB service"
                exit 1;
        else
	        export SERVICE_PLAN="Transactional"
        fi

	echo ${SERVICE_PLAN}
}

# getServiceKey service-name
getServiceKey()
{

        export CF_OUTPUT=$(bx service keys "$1" |  tr '\n' '#')
        export OUTPUT_LINE=$(echo $CF_OUTPUT | cut -d"#" -f4)
        export CF_SERVICE_KEY_NAME=$(echo $CF_OUTPUT | cut -d"#" -f5)
        if [ "name" = "$CF_SERVICE_KEY_NAME" ]
        then
                export CF_SERVICE_KEY=$(echo $CF_OUTPUT | cut -d"#" -f6)
        elif [ "No service key for service instance $1" = "${OUTPUT_LINE}" ]
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
       bx service key-create "$1" Credentials-1
       if (( $? != 0 ))
       then
               echo "Error occurred. Could not create a service key."
               exit 1
       fi
}

setDBInPropFile()
{
    sed -i.bak "s#APPCNTR_DB2_SERVER_NAME=.*\$#APPCNTR_DB2_SERVER_NAME=$(getSqldbHost)#g" ${KUBE_PROPERTY_FILE}
    sed -i.bak "s#APPCNTR_DB2_PORT=.*\$#APPCNTR_DB2_PORT=$(getSqldbPort)#g" ${KUBE_PROPERTY_FILE}
    sed -i.bak "s#APPCNTR_DB2_DATABASE_NAME=.*\$#APPCNTR_DB2_DATABASE_NAME=$(getSqldbName)#g" ${KUBE_PROPERTY_FILE}
    sed -i.bak "s#APPCNTR_DB2_USERNAME=.*\$#APPCNTR_DB2_USERNAME=$(getSqldbUsername)#g" ${KUBE_PROPERTY_FILE}
    sed -i.bak "s#APPCNTR_DB2_PASSWORD=.*\$#APPCNTR_DB2_PASSWORD=$(getSqldbPassword)#g" ${KUBE_PROPERTY_FILE}
    sed -i.bak "s#APPCNTR_DB2_SCHEMA=.*\$#APPCNTR_DB2_SCHEMA=${APPCENTER_SCHEMA_NAME}#g" ${KUBE_PROPERTY_FILE}
    if [[ "${DB_TYPE}" = "DB2" ]]
    then
        sed -i.bak "s#SSL_CONNECTION=.*\$#SSL_CONNECTION=false#g" ${KUBE_PROPERTY_FILE}
    else
        sed -i.bak "s#SSL_CONNECTION=.*\$#SSL_CONNECTION=true#g" ${KUBE_PROPERTY_FILE}
    fi
    rm ${KUBE_PROPERTY_FILE}.bak

}

configureSqldb()
{
	if [[ "${DB_TYPE}" = "DB2" ]]
	then
                createSqldbSchema DB2 databases $APPCENTER_SCHEMA_NAME
	elif [[ "${APPCENTER_DB_SERVICE_PLAN}" = "Transactional" ]]
	then
                createSqldbSchema $APPCENTER_DB_SRV_NAME databases $APPCENTER_SCHEMA_NAME
	else
		createSqldbSchema $APPCENTER_DB_SRV_NAME databases
	fi
  export KUBE_PROPERTY_FILE=./args/mfp-deployment-appcenter.yaml
  setDBInPropFile
  export KUBE_PROPERTY_FILE=./args/mfp-deployment-appcenter-with-tls.yaml
  setDBInPropFile
  export KUBE_PROPERTY_FILE=./args/mfp-deployment-lite-appcenter.yaml
  setDBInPropFile

mv ../$CUSTOMIZATION_DIR/config/appcentersqldb.xml ../$CUSTOMIZATION_DIR/config/appcentersqldb.xml-moved
cat ../$CUSTOMIZATION_DIR/config/appcentersqldb.xml-moved | grep -v "AUTO GENERATED LINE by prepareappcenterdbs.sh. DO NOT EDIT" > ../$CUSTOMIZATION_DIR/config/appcentersqldb.xml
rm ../$CUSTOMIZATION_DIR/config/appcentersqldb.xml-moved

}

createSqldbSchema()
{
        if [[ "${DB_TYPE}" = "DB2" ]]
        then
                setDB2Credentials

        fi

        if [[ "${DB_TYPE}" = "dashDB" ]]
        then
                export CURRENT_SERVICE_KEY=$(getServiceKey "$1")
                if [ "${CURRENT_SERVICE_KEY}" = "no_service_found" ]
                then
                        echo "Error occurred. The service by name $1 was not found in the current organization/space."
                        exit 1
                elif [ "${CURRENT_SERVICE_KEY}" = "no_key_found" ]
                then
                        echo "The service $1 does not have a service key. Creating a service key.."
                        createServiceKey "$1"
                        export CURRENT_SERVICE_KEY=$(getServiceKey "$1")
                fi
                setSqldbCredentials "$1" $CURRENT_SERVICE_KEY
        fi
	if [ -z "$3" ]
	then
                export ANT_OUTPUT=$(ant -f ../../common/create-appcenter-database-db2.xml -Ddatabase.db2.admin.password=$(getSqldbPassword) -Ddatabase.db2.appcenter.password=$(getSqldbPassword) -Dmfp.server.install.dir="../" -Ddatabase.db2.host=$(getSqldbHost) -Ddatabase.db2.port=$(getSqldbConfigPort) -Ddatabase.db2.admin.username=$(getSqldbUsername) -Ddatabase.db2.appcenter.schema="" -Ddatabase.db2.appcenter.username=$(getSqldbUsername) -Ddatabase.db2.appcenter.dbname=$(getSqldbName) -Ddatabase.db2.instance=SQLDB $2)
	else
                export ANT_OUTPUT=$(ant -f ../../common/create-appcenter-database-db2.xml -Ddatabase.db2.admin.password=$(getSqldbPassword) -Ddatabase.db2.appcenter.password=$(getSqldbPassword) -Dmfp.server.install.dir="../" -Ddatabase.db2.host=$(getSqldbHost) -Ddatabase.db2.port=$(getSqldbConfigPort) -Ddatabase.db2.admin.username=$(getSqldbUsername) -Ddatabase.db2.appcenter.schema="$3" -Ddatabase.db2.appcenter.username=$(getSqldbUsername) -Ddatabase.db2.appcenter.dbname=$(getSqldbName) -Ddatabase.db2.instance=SQLDB $2)
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
setSqldbCredentials()
{
	eval $( bx service key-show "$1" "$2" |  sed 's/[, ]//g' | awk -F":" '{
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

setDB2Credentials()
{
        export DB_DATABASE=${DB2_DATABASE}
        export DB_HOSTNAME=${DB2_HOST}
        export DB_PWD=${DB2_PASSWORD}
        export DB_PORT=${DB2_PORT}
        export DB_CONFIG_PORT=${DB2_PORT}
        export DB_UID=${DB2_USERNAME}
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

readParams()
{

        export INTERACTIVE_MODE=true

        # Read the IBM Bluemix Database Type
        #-----------------------------------
        INPUT_MSG="Choose your Database type. Enter 1 or 2 (mandatory).`echo $'\n1. dashDB For Transactions service or dashDB Bluemix service (Transactional plan)' $'\n2. DB2 ' $'\n' $'\nDBtype>'`"
        ERROR_MSG="Incorrect option. Choose the database type. Enter 1 or 2 (mandatory). `echo $'\n1. dashDB for Transactions service or dashDB Bluemix service (Transactional plan) ' $'\n2. DB2 ' $'\n' $'\nDBtype> '`"
        DB_TYPE=$(readDBTypeInputAsOptions "$INPUT_MSG" "$ERROR_MSG")


        if [[ "${DB_TYPE}" = "DB2" ]]
        then
                # Read the DB2 Database Host
                #--------------------------------------------------------------
    	        INPUT_MSG="Specify the hostname where DB2 is setup. (mandatory) : "
                ERROR_MSG="Hostname for DB2 cannot be empty. Specify the hostname where DB2 is configured. (mandatory) : "
                DB2_HOST=$(fnReadInput "$INPUT_MSG" "$ERROR_MSG")

                # Read the DB2 Database DB Name
                #--------------------------------------------------------------
    	        INPUT_MSG="Specify the DB2 database name. (mandatory) : "
                ERROR_MSG="Database cannot be empty. Specify the DB2 database name. (mandatory) : "
                DB2_DATABASE=$(fnReadInput "$INPUT_MSG" "$ERROR_MSG")

                # Read the DB2 Database DB PORT
                #--------------------------------------------------------------
        	read -p "Specify the port where DB2 database is configured. (defaults to 50000) (optional) : " DB2_PORT

                # Read the DB2 Database Username
                #--------------------------------------------------------------
    	        INPUT_MSG="Specify the username of the DB2 database. (mandatory) : "
                ERROR_MSG="Username cannot be empty. Specify the username of the DB2 database. (mandatory) : "
                DB2_USERNAME=$(fnReadInput "$INPUT_MSG" "$ERROR_MSG")

                # Read the DB2 Database Password
                #--------------------------------------------------------------
    	        INPUT_MSG="Specify the password of the DB2 database. (mandatory) : "
                ERROR_MSG="\nPassword for DB2 cannot be empty. Specify the password of the DB2 database. (mandatory) : "
                DB2_PASSWORD=$(fnReadPassword "$INPUT_MSG" "$ERROR_MSG")
                echo
        else

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
        fi
        # Read the Database Schema Name
        #------------------------------
        if [[ "${DB_TYPE}" = "DB2" ]] || [[ "${APPCENTER_DB_SERVICE_PLAN}" = "Transactional" ]]
        then
        	read -p "Specify the name of the database schema for application center (defaults to APPCNTR) (optional) : " APPCENTER_SCHEMA_NAME
        fi
        # if [[ "${DB_TYPE}" = "dashDB" ]]
        # then
        #         # Read the IBM Bluemix Database Service Name for Appcenter service.
        #         #--------------------------------------------------------------
        #         echo
        #         read -p "Specify the name of your Bluemix database service for storing application center data. (mandatory) : " APPCENTER_DB_SRV_NAME
        #         if [ -z $APPCENTER_DB_SRV_NAME ]
        #         then
        #                 APPCENTER_DB_SRV_NAME="${APPCENTER_DB_SRV_NAME}"
        #         fi
        #
        # fi

}

validateParams()
{
	if [ -z "${DB_TYPE}" ]
	then
    	        echo The DB_TYPE value is empty. A mandatory argument must be specified. Valid options are DB2 or dashDB Exiting...
		exit 0
	fi
        if [ "${DB_TYPE}" = "DB2" ]
        then
	        if [ -z "${DB2_HOST}" ]
	        then
    	                echo The hostname for the DB2 database is empty. A mandatory argument must be specified. Exiting...
		        exit 0
	        fi
	        if [ -z "${DB2_DATABASE}" ]
	        then
    	                echo The database name for the DB2 database is empty. A mandatory argument must be specified. Exiting...
		        exit 0
	        fi
	        if [ -z "${DB2_PORT}" ]
	        then
    	                export DB2_PORT=50000
	        fi
	        if [ -z "${DB2_USERNAME}" ]
	        then
    	                echo The username for the DB2 database is empty. A mandatory argument must be specified. Exiting...
		        exit 0
	        fi
	        if [ -z "${DB2_PASSWORD}" ]
	        then
    	                echo The password for the DB2 database is empty. A mandatory argument must be specified. Exiting...
		        exit 0
	        fi
        fi
        if [ "${DB_TYPE}" = "dashDB" ]
        then
	        if [ -z "$APPCENTER_DB_SRV_NAME" ]
	        then
    	                echo IBM Bluemix Database Service Name field for App center is empty. A mandatory argument must be specified. Exiting...
		        exit 0
	        fi
        fi
   	if [ -z "$APPCENTER_SCHEMA_NAME" ]
   	then
   		APPCENTER_SCHEMA_NAME=APPCNTR
   	fi
        export APPCENTER_SCHEMA_NAME=$(echo $APPCENTER_SCHEMA_NAME | tr '[:lower:]' '[:upper:]')

}

#main

debug "==========================================================================="
debug prepareappcenterdbs.sh start: $(date)
debug "==========================================================================="


export PATH=$PATH:../../mfpf-libs/apache-ant-1.9.4/bin

#export HELM_PROPERTY_FILE=./args/values.yaml
if [ -z $CUSTOMIZATION_DIR ]
then
    export CUSTOMIZATION_DIR="usr"
fi

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
         -t | --type)
            DB_TYPE="$2";
            shift
            ;;
         -h | --host)
            DB2_HOST="$2";
            shift
            ;;
         -d | --database)
            DB2_DATABASE="$2";
            shift
            ;;
         -r | --port)
            DB2_PORT="$2";
            shift
            ;;
         -u | --username)
            DB2_USERNAME="$2";
            shift
            ;;
         -pw | --password)
            DB2_PASSWORD="$2";
            shift
            ;;
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
        if [ "${DB_TYPE}" = "dashDB" ]
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
fi


output "Arguments : "
output "----------- "
output
output "DB_TYPE              : " $DB_TYPE
if [[ "${DB_TYPE}" = "DB2" ]]
then
        output "DB2_HOST              : " $DB2_HOST
        output "DB2_DATABASE          : " $DB2_DATABASE
        output "DB2_PORT              : " $DB2_PORT
        output "DB2_USERNAME          : " $DB2_USERNAME
        output "DB2_PASSWORD          : " XXXXXXXX
fi
if [[ "${DB_TYPE}" = "dashDB" ]]
then
        output "APPCENTER_DB_SRV_NAME    : " $APPCENTER_DB_SRV_NAME
fi
if [[ "${DB_TYPE}" = "DB2" ]] || [[ "${APPCENTER_DB_SERVICE_PLAN}" = "Transactional" ]]
then
	output "APPCENTER_SCHEMA_NAME   : " $APPCENTER_SCHEMA_NAME
fi

if [ "${INTERACTIVE_MODE}" = "true" ]
then
    export ARGS_PROPS_FILE="prepareappcenterdbs.properties"
    recordInputParams DB_TYPE="${DB_TYPE}"#DB2_HOST="${DB2_HOST}"#DB2_DATABASE="${DB2_DATABASE}"#DB2_PORT="${DB2_PORT}"#DB2_USERNAME="${DB2_USERNAME}"#DB2_PASSWORD=#APPCENTER_DB_SRV_NAME="${APPCENTER_DB_SRV_NAME}"#APPCENTER_SCHEMA_NAME="${APPCENTER_SCHEMA_NAME}"
fi

debug
debug "JAVA_HOME:" $JAVA_HOME
debug " "

configureSqldb

output
output The command prepareappcenterdbs.sh completed successfully.
output
debug "==========================================================================="
debug prepareappcenterdbs.sh end: $(date)
debug "==========================================================================="
