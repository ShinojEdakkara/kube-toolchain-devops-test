#   Licensed Materials - Property of IBM 
#   5725-I43 (C) Copyright IBM Corp. 2015, 2016. All Rights Reserved.
#   US Government Users Restricted Rights - Use, duplication or
#   disclosure restricted by GSA ADP Schedule Contract with IBM Corp.  
   
#!/usr/bin/bash

usage() 
{
   echo 
   echo " Preparing the MobileFirst Application Center app "
   echo " ------------------------------------------------------------ "
   echo " This script loads, customizes and pushes the MobileFirst Application Center "
   echo " as a Java for Liberty app on Bluemix."
   echo " Prerequisite: The prepareappcenterdbs.sh script is run before running this script."
   echo
   echo " Silent Execution (arguments provided as command-line arguments): "
   echo "   USAGE: prepareappcenter.sh <command-line arguments> "
   echo "   command-line arguments: "
   echo "     -n | --name APP_NAME                Name of the MobileFirst application center app"
   echo
   echo " Silent Execution (arguments loaded from file): "
   echo "   USAGE: prepareappcenter.sh <path to the file from which arguments are read> "
   echo "          See args/prepareappcenter.properties for the list of arguments."
   echo 
   echo " Interactive Execution: "
   echo "   USAGE: prepareappcenter.sh"
   echo
   exit 1
}

readParams()
{
    export INTERACTIVE_MODE=true
    # Read the name for the MobileFirst Application Center app
    #----------------------------------------------
   INPUT_MSG="Specify the name of the app (mandatory) : "
   ERROR_MSG="App name cannot be empty. Specify the name of the app (mandatory) : "
   APP_NAME=$(fnReadInput "$INPUT_MSG" "$ERROR_MSG")

}

validateParams() 
{
	if [ -z "$APP_NAME" ]
	then
	    	echo app name is empty. A mandatory argument must be specified. Exiting...
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
         -t | --trace)
            TRACE_SPEC="$2";
            shift
            ;;
         -l | --maxlog)
            MAX_LOG_FILES="$2";
            shift
            ;;
         -s | --maxlogsize)
            MAX_LOG_FILE_SIZE="$2";
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

echo
echo "Arguments : "
echo "----------- "
echo 
echo "APP_NAME : " $APP_NAME
echo

echo

if [ "${INTERACTIVE_MODE}" = "true" ]
then
    export ARGS_PROPS_FILE="prepareappcenter.properties"
    recordInputParams APP_NAME="${APP_NAME}"
fi

if [ ! -e ../mfp-appcenter-assembly ]
then
    mkdir ../mfp-appcenter-assembly
fi
cd ../mfp-appcenter-assembly
tar -zxvf ../../mfpf-libs/mfp-appcenter.tgz >/dev/null 2>&1
if (( $? != 0 ))
then
     echo "Unable to write into directory: ../mfp-appcenter-assembly. Exiting..."
fi

if [ ! -e ../mfp-appcenter-assembly/wlp/usr/servers/appcenter/resources/security/ ]
then
    mkdir -p ../mfp-appcenter-assembly/wlp/usr/servers/appcenter/resources/security/
fi
cp ../usr/security/* ../mfp-appcenter-assembly/wlp/usr/servers/appcenter/resources/security/

cp ../usr/env/* ../mfp-appcenter-assembly/wlp/usr/servers/appcenter/
cp -R ../mfp-appcenter-assembly/opt/ibm/wlp/usr/* ../mfp-appcenter-assembly/wlp/usr/

if [ ! -e ../mfp-appcenter-assembly/wlp/usr/servers/appcenter/configDropins/overrides/ ]
then
    mkdir -p ../mfp-appcenter-assembly/wlp/usr/servers/appcenter/configDropins/overrides/
fi
cp ../usr/config/*.xml ../mfp-appcenter-assembly/wlp/usr/servers/appcenter/configDropins/overrides/

cd ../mfp-appcenter-assembly
if [ -f ./mfpappcenter.zip ]
then
    rm -f ./mfpappcenter.zip
fi
zip -r mfpappcenter.zip wlp >/dev/null 2>&1
cd ../scripts

echo "Pushing the MobileFirst Application Server to IBM BLuemix.."
#cf push $APP_NAME -p ../mfp-appcenter-assembly/mfpappcenter.zip --no-start 
cf push "${APP_NAME}" -p ../mfp-appcenter-assembly/mfpappcenter.zip --no-start --no-route -t 180
if (( $? != 0 ))
then
    echo "Error occurred. Failed to create the app on Bluemix. Exitting..."
    exit 1
fi

