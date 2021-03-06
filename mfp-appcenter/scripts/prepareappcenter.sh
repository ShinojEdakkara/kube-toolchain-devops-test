#   Licensed Materials - Property of IBM 
#   5725-I43 (C) Copyright IBM Corp. 2015, 2016. All Rights Reserved.
#   US Government Users Restricted Rights - Use, duplication or
#   disclosure restricted by GSA ADP Schedule Contract with IBM Corp.  
   
#!/usr/bin/bash

usage() 
{
   echo 
   echo " Preparing the MobileFirst Platform Application Center Image "
   echo " ------------------------------------------------------------ "
   echo " This script loads, customizes, tags, and pushes the MobileFirst Platform Application Center image"
   echo " to the IBM Containers service on Bluemix."
   echo " Prerequisite: The prepareappcenterdbs.sh script is run before running this script."
   echo
   echo " Silent Execution (arguments provided as command-line arguments): "
   echo "   USAGE: prepareappcenter.sh <command-line arguments> "
   echo "   command-line arguments: "
   echo "     -t | --tag SERVER_IMAGE_TAG   Name to be used for the customized MobileFirst Application Center image"
   echo "                                     Format: registryUrl/namespace/name:tag"
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
    # Read the name for the MobileFirst Platform Application Center image
    #--------------------------------------------------------------------
    INPUT_MSG="Specify the name for the MobileFirst Platform Application Center image. Should be of form registryUrl/repositoryNamespace/imagename (mandatory) : "
    ERROR_MSG="Name for MobileFirst Platform Application Center image cannot be empty. Specify the name for the image. (mandatory) : "
    SERVER_IMAGE_TAG=$(fnReadInput "$INPUT_MSG" "$ERROR_MSG")
      
}

validateParams() 
{
		if [ -z "$SERVER_IMAGE_TAG" ]
		then
	    	echo MobileFirst Platform Application Center Image Name is empty. A mandatory argument must be specified. Exiting...
			exit 0
		fi
}

clean_up() {
	# Perform clean up before exiting
	cd "${absoluteScriptDir}"
        
    if [ -d ../dependencies ]
    then
        mv ../dependencies ../../dependencies
    fi
    if [ -d ../mfpf-libs ]
    then
        mv ../mfpf-libs ../../mfpf-libs
    fi

    if [ -d ../licenses ]
    then 
        rm -rf ../licenses
    fi
}

cd "$( dirname "$0" )"

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
         -t | --tag)
            SERVER_IMAGE_TAG="$2";
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


trap clean_up 0 1 2 3 15

scriptDir=`dirname $0`
absoluteScriptDir=`pwd`/${scriptDir}/


echo "Arguments : "
echo "----------- "
echo 
echo "SERVER_IMAGE_NAME : " $SERVER_IMAGE_TAG
echo

# validate if mandatory db related entries are added into server.env
source ../usr/env/server.env

if [[ -z "${APPCNTR_DB2_SERVER_NAME}" ]]
then
        echo "Error occurred. Database details were not found in the file ../usr/env/server.env"
        echo "You need to enter the credentials of your database (dashDB Transactional service) in the file ../usr/env/server.env"
        exit 1
fi

if [[ ! -z "${APPCNTR_DB2_SERVER_NAME}" ]]
then
        # Configuration seems to be for for dashdb
        if [[ -z "${APPCNTR_DB2_PORT}" || -z "${APPCNTR_DB2_DATABASE_NAME}" || -z "${APPCNTR_DB2_USERNAME}" || -z "${APPCNTR_DB2_PASSWORD}" ]]
        then
                echo "Error occurred. One of the fields in server.env is not set. Check the entries APPCNTR_DB2_* in the file ../usr/env/server.env"
                exit 1
        fi
fi

mv ../../dependencies ../dependencies
mv ../../mfpf-libs ../mfpf-libs
cp -rf ../../licenses ../licenses

echo "Building the MobileFirst Platform Application Center image : " $SERVER_IMAGE_TAG
docker build -t $SERVER_IMAGE_TAG ../
if (( $? != 0 ))
then
       echo "The command docker build -t $SERVER_IMAGE_TAG ../ failed. Exitting."
       exit 1
fi
mv ../dependencies ../../dependencies
mv ../mfpf-libs ../../mfpf-libs
rm -rf ../licenses

echo "Pushing the MobileFirst Platform Application Center image to the IBM Containers registry.."
docker push $SERVER_IMAGE_TAG
