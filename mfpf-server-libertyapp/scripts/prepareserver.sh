#   Licensed Materials - Property of IBM 
#   5725-I43 (C) Copyright IBM Corp. 2015, 2016. All Rights Reserved.
#   US Government Users Restricted Rights - Use, duplication or
#   disclosure restricted by GSA ADP Schedule Contract with IBM Corp.  
   
#!/usr/bin/bash

usage() 
{
   echo 
   echo " Preparing the MobileFirst Platform Foundation Server app "
   echo " ------------------------------------------------------------ "
   echo " This script loads, customizes and pushes the MobileFirst Server "
   echo " as a Java for Liberty app on Bluemix."
   echo " Prerequisite: The prepareserverdbs.sh script is run before running this script."
   echo
   echo " Silent Execution (arguments provided as command-line arguments): "
   echo "   USAGE: prepareserver.sh <command-line arguments> "
   echo "   command-line arguments: "
   echo "     -n | --name APP_NAME                Name of the MobileFirst Server app"
   echo
   echo " Silent Execution (arguments loaded from file): "
   echo "   USAGE: prepareserver.sh <path to the file from which arguments are read> "
   echo "          See args/prepareserver.properties for the list of arguments."
   echo 
   echo " Interactive Execution: "
   echo "   USAGE: prepareserver.sh"
   echo
   exit 1
}

readParams()
{
    export INTERACTIVE_MODE=true
    # Read the name for the MobileFirst Server app
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
    export ARGS_PROPS_FILE="prepareserver.properties"
    recordInputParams APP_NAME="${APP_NAME}"
fi

if [ ! -e ../mfpf-assembly ]
then
    mkdir ../mfpf-assembly
fi
cd ../mfpf-assembly
tar -zxvf ../../mfpf-libs/mfpf-server-lbp.tgz  >/dev/null 2>&1
RET_VAL=$?
if (( $? != 0 ))
then
     echo "Unable to write into directory: ../mfpf-assembly. Exiting..."
fi
tar -zxvf ../../mfpf-libs/mfpf-server-common.tgz >/dev/null 2>&1
RET_VAL=$?
if (( $? != 0 ))
then
     echo "Unable to write into directory: ../mfpf-assembly. Exiting..."
fi

if [ ! -e ../mfpf-assembly/wlp/usr/servers/mfp/resources/security/ ]
then
    mkdir -p ../mfpf-assembly/wlp/usr/servers/mfp/resources/security/
fi
cp ../usr/security/* ../mfpf-assembly/wlp/usr/servers/mfp/resources/security/

cp ../usr/env/* ../mfpf-assembly/wlp/usr/servers/mfp/

if [ ! -e ../mfpf-assembly/wlp/usr/servers/mfp/configDropins/overrides/ ]
then
    mkdir -p ../mfpf-assembly/wlp/usr/servers/mfp/configDropins/overrides/
fi
cp ../usr/config/*.xml ../mfpf-assembly/wlp/usr/servers/mfp/configDropins/overrides/

cd ../mfpf-assembly
if [ -f ./mfpf.zip ]
then
    rm -f ./mfpf.zip
fi
zip -r mfpf.zip wlp .profile.d >/dev/null 2>&1
cd ../scripts

echo "Pushing the MobileFirst Server to IBM BLuemix.."
#cf push $APP_NAME -p ../mfpf-assembly/mfpf.zip --no-start 
cf push "${APP_NAME}" -p ../mfpf-assembly/mfpf.zip --no-start --no-route -t 180
if (( $? != 0 ))
then
    echo "Error occurred. Failed to create the app on Bluemix. Exitting..."
    exit 1
fi

