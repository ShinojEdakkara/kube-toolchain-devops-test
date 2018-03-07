#   Licensed Materials - Property of IBM 
#   5725-I43 (C) Copyright IBM Corp. 2011, 2015. All Rights Reserved.
#   US Government Users Restricted Rights - Use, duplication or
#   disclosure restricted by GSA ADP Schedule Contract with IBM Corp.  
   
#!/usr/bin/bash

usage() 
{
   echo 
   echo " Start a MobileFirst Platform Application Center Server liberty app "
   echo " --------------------------------------------------------------------------------- "
   echo " This script starts the MobileFirst Application Center Server "
   echo " Prerequisite: The prepareappcenter.sh script must be run before running this script."
   echo
   echo " Silent Execution (arguments provided as command line arguments):"
   echo "   USAGE: startappcenter.sh <command line arguments> "
   echo "     -n | --name APP_NAME       Name of the MobileFirst Server app"
   echo "     -h | --host APP_HOST       (Optional) The host name of the route. The default is the name given for APP_NAME"
   echo "     -d | --domain DOMAIN_NAME  (Optional) The domain name of the route. The default is mybluemix.net"
   echo "     -i | --instances INSTANCES (Optional) The desired number of instances. The default value is 2"
   echo "     -m | --memory SERVER_MEM   (Optional) Assign a memory size limit to the app in megabytes (MB)"
   echo "                                Accepted values are 1024 (default), 2048,..."
   echo 

   
   echo " Silent Execution (arguments loaded from file):"
   echo "   USAGE: startappcenter.sh <path to the file from which arguments are read>"
   echo "          See args/startappcenter.properties for the list of arguments."
   echo 
   echo " Interactive Execution: "
   echo "   USAGE: startappcenter.sh"
   echo
   exit 1
}

readParams()
{
      export INTERACTIVE_MODE=true
      # Read the name for the MobileFirst Application center app
      #----------------------------------------------
      INPUT_MSG="Specify the name of the app (mandatory) : "
      ERROR_MSG="App name cannot be empty. Specify the name of the app (mandatory) : "
      APP_NAME=$(fnReadInput "$INPUT_MSG" "$ERROR_MSG")

      # Read the host name of the route
      #--------------------------------
      read -p "Specify the host name of the route (special characters are not allowed). The default value is the name of the app (optional) : " APP_HOST

      # Read the domain of the route
      #-----------------------------
      read -p "Specify the domain of the route. The default value is mybluemix.net (optional) : " DOMAIN_NAME

      # Read the memory for the MobileFirst Server app
      #-----------------------------------------------------
      INPUT_MSG="Specify the memory size limit (in MB) for the MobileFirst Server app. Accepted values are 1024,2048.... The default value is 1024 (optional) : "
      ERROR_MSG="Error due to non-numeric input. Specify a valid value. Valid values are 1024, 2048,... The default value is 1024 MB. (optional) : "
      SERVER_MEM=$(fnReadNumericInput "$INPUT_MSG" "$ERROR_MSG" "1024")



      # Read the desired number of instances
      #-------------------------------------
      INPUT_MSG="Specify the number of instances to create. The default value is 2 (optional) : "
      ERROR_MSG="Error due to non-numeric input. Specify the number of instances to create. The default value is 2 (optional) : "
      INSTANCES=$(fnReadNumericInput "$INPUT_MSG" "$ERROR_MSG" "2")


}

validateParams() 
{
        if [ -z "$APP_NAME" ]
        then
             echo App name is empty. A mandatory argument must be specified. Exiting...
             exit 0
        fi

        if [ -z "$APP_HOST" ]
        then
                export APP_HOST=$(echo "${APP_NAME}" | tr ' ' '_')
                
        fi

        if [ `expr "$APP_HOST" : ".*[!@#\$%^\&*()_+].*"` -gt 0 ];
        then
            echo Host name should not contain special characters. Exiting...
            exit 0
        fi


        if [ -z "$DOMAIN_NAME" ]
        then
            export DOMAIN_NAME=mybluemix.net
        fi

        if [ -z $INSTANCES ]
        then
             INSTANCES=2;
        fi
        if [ "$(isNumber $INSTANCES)" = "1" ]
        then
            echo Required number of instances must be a number. Exiting...
            exit 0
        fi
        if [ -z "$SERVER_MEM" ]
        then
           SERVER_MEM=1024
        fi

        if [ "$(isNumber $SERVER_MEM)" = "1" ]
        then
            echo  Required App memory must be a number. Exiting...
            exit 0
        fi
}

#clean_up() {
        # Perform clean up before exiting

#}
#need to assemble the app zip 

source ../../common/common.sh

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
         -n | --name)
            APP_NAME="$2";
            shift
            ;;
         -i | --instances)
            INSTANCES="$2";
            shift
            ;;
         -h | --host)
            APP_HOST="$2";
            shift
            ;;
         -d | --domain)
            DOMAIN_NAME="$2";
            shift
            ;;
         -m | --memory)
            SERVER_MEM="$2";
            shift
            ;;
         *)
            usage
            ;;
      esac
      shift
   done
fi
echo
echo


validateParams

#main

echo
echo "Arguments : "
echo "----------- "
echo 
echo "APP_NAME : " $APP_NAME
echo "APP_HOST : " $APP_HOST
echo "DOMAIN_NAME : " $DOMAIN_NAME
echo "INSTANCES : " $INSTANCES
echo "SERVER_MEM : " $SERVER_MEM
echo

if [ "${INTERACTIVE_MODE}" = "true" ]
then
    export ARGS_PROPS_FILE="startappcenter.properties"
    recordInputParams APP_NAME="${APP_NAME}"#APP_HOST=$APP_HOST#DOMAIN_NAME=$DOMAIN_NAME#INSTANCES=$INSTANCES#SERVER_MEM=$SERVER_MEM
fi

export CURRENT_SPACE=$(cf target | grep "Space:" | cut -d":" -f2)


export CHECK_ROUTE_OUTPUT=$(cf check-route ${APP_HOST} ${DOMAIN_NAME})
echo ${CHECK_ROUTE_OUTPUT}

echo ${CHECK_ROUTE_OUTPUT} | grep "FAILED"
if (( $? == 0 ))
then
    echo "Exiting ..."
    exit 1
fi

echo ${CHECK_ROUTE_OUTPUT} | grep "does exist" >/dev/null 2>&1
if (( $? == 0 ))
then
    # does route exist in current space
    export ROUTES_OUTPUT=$(cf routes | grep ${APP_HOST} | grep ${DOMAIN_NAME})
    if [[ "${ROUTES_OUTPUT}" != "" ]]
    then
        export ASSOCIATED_APP=$(echo $ROUTES_OUTPUT | cut -d" " -f4)
        if [[ "${ASSOCIATED_APP}" != "" ]]  && [[ "${ASSOCIATED_APP}" != "${APP_NAME}" ]]
        then
            echo "The provided route is already associated with the app: ${ASSOCIATED_APP}. Exiting ..."
            exit 1
        else
            echo "The route already exists in the space. Reusing the same route..."
        fi
    else
# Handle this: route exists in org in different space: HA ?? - we may have to allow this in future
#export ORG_ROUTES_OUTPUT=$(cf routes --orglevel | grep mymfpapp | grep mybluemix.net)
        echo "The route already exists, but is not owned by the current space. Exiting... "
        exit 1
    fi
fi


cf map-route "${APP_NAME}" ${DOMAIN_NAME} --hostname ${APP_HOST}
if (( $? != 0 ))
then
    echo "Failed to map the provided route to the app. Exiting..."
    exit 1
fi
cf set-env "${APP_NAME}" MF_REGION $(getDetails LIBAPP_"${APP_NAME}") >/dev/null 2>&1
cf scale "${APP_NAME}" -i ${INSTANCES} -m ${SERVER_MEM}M -k 2G -f
