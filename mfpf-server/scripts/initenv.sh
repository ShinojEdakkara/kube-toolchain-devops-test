#   Licensed Materials - Property of IBM 
#   5725-I43 (C) Copyright IBM Corp. 2011, 2015. All Rights Reserved.
#   US Government Users Restricted Rights - Use, duplication or
#   disclosure restricted by GSA ADP Schedule Contract with IBM Corp.  
   
#!/usr/bin/bash

source ../../common/common.sh
source ../../common/initenv.sh

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
verifyCFICCLI


echo "Logging into IBM Containers service on Bluemix.."
cf login -a "${BLUEMIX_API_URL}" -u "${BLUEMIX_USER}" -p "${BLUEMIX_PASSWORD}" -o "${BLUEMIX_ORG}" -s "${BLUEMIX_SPACE}"
cf ic login
