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
   echo "     -t | --tag APPCENTER_IMAGE_TAG   Name to be used for the customized MobileFirst Application Center image"
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
    export INTERACTIVE_MODE=true
    # Read the name for the MobileFirst Server image
    #----------------------------------------------
    INPUT_MSG="Specify the name for the MobileFirst Server image. Should be of form registryUrl/repositoryNamespace/imagename (mandatory) : "
    ERROR_MSG="Name for MobileFirst Server image cannot be empty. Specify the name for the image. (mandatory) : "
    SERVER_IMAGE_TAG=$(fnReadInput "$INPUT_MSG" "$ERROR_MSG")
}

validateParams()
{
		if [ -z "$SERVER_IMAGE_TAG" ]
		then
			echo MobileFirst Platform Application Center Image Name is empty. A mandatory argument must be specified. Exiting...
			exit 0
                else
			export SERVER_IMAGE_TAG=$(echo ${SERVER_IMAGE_TAG} | tr '[:upper:]' '[:lower:]')

		fi
}



cd "$( dirname "$0" )"

source ../../common/common.sh
source ../../common/prepareserver.sh

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



scriptDir=`dirname $0`
absoluteScriptDir=`pwd`/${scriptDir}/


echo "Arguments : "
echo "----------- "
echo
echo "SERVER_IMAGE_NAME : " $SERVER_IMAGE_TAG
echo

if [ "${INTERACTIVE_MODE}" = "true" ]
then
    export ARGS_PROPS_FILE="prepareappcenter.properties"
    recordInputParams SERVER_IMAGE_TAG=$SERVER_IMAGE_TAG
fi
cp  ../Dockerfile-mfp-appcenter ../Dockerfile
dockerBuild ${SERVER_IMAGE_TAG}

echo "Pushing the MobileFirst Appcenter image to the IBM Containers registry.."
docker push ${SERVER_IMAGE_TAG}

echo "################################################################################################"
echo
echo " You are now ready to deploy these images on your Kubernetes Cluster"
echo
echo " Next Steps:"
echo " -----------"
echo " 1. Set your terminal context to your cluster:"
echo "           bx cs cluster-config <cluster-name>"
echo
echo "    To know your <cluster-name>, type the command: "
echo "           bx cs clusters"
echo
echo "    In the output, the path to your configuration file is displayed as a command to set an environment variable, for example:"
echo
echo "           export KUBECONFIG=/Users/ibm/.bluemix/plugins/container-service/clusters/my-cluster/kube-config-prod-dal12-my-cluster.yml"
echo
echo "    Copy and paste the command to set the environment variable in your terminal and press Enter."
echo
echo " 2. Create the Kubernetes Deployments"
echo "    Edit the yaml file args/mfpf-deployment-appcenter.yaml, and fill the details."
echo "    Specifically, all entries in-between < and > are to be filled before executing the kubectl command."
echo
echo "    args/mfpf-deployment-appcenter.yaml contains the deployment for the following:"
echo "    - A kubernetes deployment for MFP Appcenter consisting of 3 instances (replicas), of 1024MB memory and 1Core CPU"
echo "    - A kubernetes service for MFP Appcenter"
echo "    - An ingress for the whole setup including all the REST endpints for MFP Server and Analytics"
echo "    - A configMap to make the environment variables available in the MFP Server Appcenter"
echo
echo "    Execute the following command:"
echo
echo "            kubectl create -f ./args/mfpf-deployment-appcenter.yaml"
echo ""
echo "    After creation, to use the Kubernetes UI, execute the following command"
echo "           kubectl proxy "
echo "    Open your localhost:8001/ui in your browser "
echo ""
echo "################################################################################################"
