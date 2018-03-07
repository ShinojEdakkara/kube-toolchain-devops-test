#   Licensed Materials - Property of IBM 
#   5725-I43 (C) Copyright IBM Corp. 2011, 2015. All Rights Reserved.
#   US Government Users Restricted Rights - Use, duplication or
#   disclosure restricted by GSA ADP Schedule Contract with IBM Corp.  
   
#!/usr/bin/bash

source ../../common/common.sh



commonUsage() 
{
  
   echo " Silent Execution (arguments provided as command-line arguments) : "
   echo "   USAGE: initenv.sh <command-line arguments> "
   echo "   command-line arguments: "
   echo "   -a | --api BLUEMIX_API_URL       (Optional) Bluemix API endpoint. Defaults to https://api.ng.bluemix.net"
   echo "   -u | --user BLUEMIX_USER         Bluemix user ID or email address"
   echo "   -p | --password BLUEMIX_PASSWORD Bluemix password"
   echo "   -o | --org BLUEMIX_ORG           Bluemix organization"
   echo "   -s | --space BLUEMIX_SPACE       Bluemix space"
   echo "   -c | --accountid BLUEMIX_ACCOUNT_ID       Bluemix account ID"
   echo
   echo " Silent Execution (arguments loaded from file) : "
   echo "   USAGE: initenv.sh <path to the file from which arguments are read> "
   echo "          See args/initenv.properties for the list of arguments."
   echo 
   echo " Interactive Execution: "
   echo "   USAGE: initenv.sh"
   echo
   exit 1
}

readParams()
{
          export INTERACTIVE_MODE=true
          # Read the IBM Bluemix API endpoint
          #----------------------------------
          INPUT_MSG="Specify the Bluemix API endpoint. The default value is https://api.ng.bluemix.net (optional) : "
          ERROR_MSG="Invalid URL. Specify the Bluemix API endpoint. The default value is https://api.ng.bluemix.net (optional) : "
          DEFAULT_URL="https://api.ng.bluemix.net"
          BLUEMIX_API_URL=$(fnReadURL "$INPUT_MSG" "$ERROR_MSG" "$DEFAULT_URL")
}

validateParams() 
{
		if [ -z "$BLUEMIX_API_URL" ]
		then
		    BLUEMIX_API_URL=https://api.ng.bluemix.net
		fi
		
		if [ "$(validateURL $BLUEMIX_API_URL)" = "1" ]
		then
		    echo IBM Bluemix API URL is incorrect. Exiting...
		    exit 0
		fi
	
		if [ -z "$BLUEMIX_USER" ]
		then
		    echo IBM Bluemix Email ID/UserID field is empty. A mandatory argument must be specified. Exiting...
		    exit 0
		fi
		
		if [ -z "$BLUEMIX_PASSWORD" ]
		then
		    echo IBM Bluemix Password field is empty. A mandatory argument must be specified. Exiting...
		    exit 0
		fi
		
		if [ -z "$BLUEMIX_ORG" ]
		then
		    echo IBM Bluemix Organization field is empty. A mandatory argument must be specified. Exiting...
		    exit 0
		fi
		
		if [ -z "$BLUEMIX_SPACE" ]
		then
		    echo IBM Bluemix Space field is empty. A mandatory argument must be specified. Exiting...
		    exit 0
		fi
}

processInputs()
{
	
	cd "$( dirname "$0" )"
	
	if [ $# == 0 ]
	then
	    readParams
	elif [ "$#" -eq 1 -a -f "$1" ]
	then
	    source "$1"
	elif [ "$1" = "-h" -o "$1" = "--help" ]
	then
	    usage
	exit 0
	else
	while [ $# -gt 0 ]; do
		case "$1" in
			-a | --api)
				BLUEMIX_API_URL="$2";
				shift
				;;
			-c | --accountid)
				BLUEMIX_ACCOUNT_ID="$2";
				shift
				;;
			-u | --user)
				BLUEMIX_USER="$2";
				shift
				;;
			-p | --password)
				BLUEMIX_PASSWORD="$2";
				shift
				;;
			-o | --org)
				BLUEMIX_ORG="$2";
				shift
				;;
			-s | --space)
				BLUEMIX_SPACE="$2";
				shift
				;;
			*)
				usage
				;;
		esac
		shift
	done
	fi

        if [[ "${INTERACTIVE_MODE}" != "true" ]]
        then	
	   validateParams
        fi

	#main

        if [ "${INTERACTIVE_MODE}" = "true" ]
        then
            export CURRENT_DIR=$(dirname $0)
            export ARGS_PROPS_FILE="initenv.properties"
            recordInputParams BLUEMIX_API_URL="${BLUEMIX_API_URL}"#BLUEMIX_USER="${BLUEMIX_USER}"#BLUEMIX_PASSWORD=#BLUEMIX_ORG="${BLUEMIX_ORG}"#BLUEMIX_SPACE="${BLUEMIX_SPACE}"
        fi
}



source ../../common/common.sh

usage() 
{
   echo 
   echo " Initializing MobileFirst Platform Foundation on IBM Containers "
   echo " -------------------------------------------------------------- "
   echo " This script creates an environment for building and running IBM MobileFirst Platform Foundation  "
   echo " on the IBM Containers service on Bluemix."
   echo
   commonUsage
}

processInputs $*
verifyBXCSCLI
verifyBXCRCLI


if [[ "${INTERACTIVE_MODE}" = "true" ]]
then
    bx login -a "${BLUEMIX_API_URL}"
    if (( $? != 0 ))
    then
        echo "Login Failed. Exiting..."
        exit 1
    fi
    echo "Using bx target --cf to login to Org and Space"
    bx target --cf
    eval $( bx target |  sed 's/ *//g' | awk -F":" '{
                                                                     if ($1 == "User") {
                                                                             print "export BLUEMIX_USER="$2;
                                                                     } else if ($1 == "Org") {
                                                                             print "export BLUEMIX_ORG="$2;
                                                                     } else if ($1 == "Space") {
                                                                             print "export BLUEMIX_SPACE="$2;
                                                                     }

                                                             }' ) 
    export BLUEMIX_ACCOUNT_ID=$(bx target | grep "Account:" | sed 's/.*(//g' | sed 's/).*//g' )
    export ARGS_PROPS_FILE="initenv.properties"
    recordInputParams BLUEMIX_API_URL="${BLUEMIX_API_URL}"#BLUEMIX_USER="${BLUEMIX_USER}"#BLUEMIX_PASSWORD=#BLUEMIX_ORG="${BLUEMIX_ORG}"#BLUEMIX_SPACE="${BLUEMIX_SPACE}"#BLUEMIX_ACCOUNT_ID="${BLUEMIX_ACCOUNT_ID}"
else
    bx login -a "${BLUEMIX_API_URL}" -u "${BLUEMIX_USER}" -p "${BLUEMIX_PASSWORD}" -o "${BLUEMIX_ORG}" -s "${BLUEMIX_SPACE}" -c "${BLUEMIX_ACCOUNT_ID}"
fi
echo "Logging into container-service on Bluemix.."
bx cs init
echo "Logging into container-registry on Bluemix.."
bx cr login

