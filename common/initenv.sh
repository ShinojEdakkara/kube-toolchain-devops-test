#   Licensed Materials - Property of IBM 
#   5725-I43 (C) Copyright IBM Corp. 2011, 2015. All Rights Reserved.
#   US Government Users Restricted Rights - Use, duplication or
#   disclosure restricted by GSA ADP Schedule Contract with IBM Corp.  
   
#!/usr/bin/bash



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

	  # Read the IBM Bluemix User ID or Email    
	  #--------------------------------------
	  INPUT_MSG="Specify your IBM Bluemix user ID or email address (mandatory) : "
	  ERROR_MSG="User ID Field cannot be empty. Specify your IBM Bluemix user ID or email address (mandatory) : "
	  BLUEMIX_USER=$(fnReadInput "$INPUT_MSG" "$ERROR_MSG")
	      
	  # Read the IBM Bluemix Password
	  #------------------------------
	  INPUT_MSG="Specify your IBM Bluemix password (mandatory) : "
	  ERROR_MSG="`echo $'\n'`Password cannot be empty. Specify your IBM Bluemix password (mandatory) : "
	  BLUEMIX_PASSWORD=$(fnReadPassword "$INPUT_MSG" "$ERROR_MSG")
	  echo ""
		
	  # Read the IBM Bluemix Organization
	  #----------------------------------
	  INPUT_MSG="Specify your IBM Bluemix organization (mandatory) : "
	  ERROR_MSG="Organization cannot be empty. Specify your IBM Bluemix organization (mandatory) : "
	  BLUEMIX_ORG=$(fnReadInput "$INPUT_MSG" "$ERROR_MSG")
	
	  # Read the IBM Bluemix Space 
	  #---------------------------
	  INPUT_MSG="Specify your IBM Bluemix space (mandatory) : "
	  ERROR_MSG="Bluemix Space field cannot be empty. Specify your IBM Bluemix space (mandatory) : "
	  BLUEMIX_SPACE=$(fnReadInput "$INPUT_MSG" "$ERROR_MSG")

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
	
	validateParams

	#main



	echo "Arguments : "
	echo "----------- "
	echo 
	echo "BLUEMIX_API_URL : " $BLUEMIX_API_URL
	echo "BLUEMIX_USER : " $BLUEMIX_USER
	echo "BLUEMIX_PASSWORD : " XXXXXXXX
	echo "BLUEMIX_ORG : " $BLUEMIX_ORG
	echo "BLUEMIX_SPACE : " $BLUEMIX_SPACE
	echo 

        if [ "${INTERACTIVE_MODE}" = "true" ]
        then
            export CURRENT_DIR=$(dirname $0)
            export ARGS_PROPS_FILE="initenv.properties"
            recordInputParams BLUEMIX_API_URL="${BLUEMIX_API_URL}"#BLUEMIX_USER="${BLUEMIX_USER}"#BLUEMIX_PASSWORD=#BLUEMIX_ORG="${BLUEMIX_ORG}"#BLUEMIX_SPACE="${BLUEMIX_SPACE}"
        fi
}
