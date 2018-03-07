All scripts in the /scripts folder support the following methods for passing-in the required parameters: 
1. Command-line arguments 
2. From file (See args/ folder for related .properties files)
3. Interactively when you run the script with no arguments.

The usage / help of every script can be obtained by using the -h or --help command line arguments

Step 1: Prerequisite: Create a database for MobileFirst data
------------------------------------------------------------
   Option 1: A Bluemix Service
   ---------------------------
       Create a Bluemix service for the database that will be used by MobileFirst.
       Supported database services are : dashDB For Transactions service or dashDB service (Transactional plans only)

       Alternatively, you can use the following cf commands:
       a) Login to Bluemix:
          # cf login
       b) Create the service of your choice. Choose the right service-type & service-plan.  Supported service-type, service-plan combinations are :
                 i) dashDB For Transactions & any plan
                ii) dashDB &  Any Enterprise Transactional(OLTP) plan. For ex. EnterpriseTransactional2.8.500, EnterpriseTransactional12.128.1400 
                
          # cf create-service <bluemix-service-type> <bluemix-service-plan> <bluemix-service-name>
       Note: Some of the plans of dashDB service are instant activation. For other service plans, you may need to contact the sales team to order the service instance

   Option 2: Bring your on DB2 database
   --------------------------------
       Create a DB2 database and connect the MobileFirst server to your database
       Supported database: IBM DB2        Create a DB2 database. You will need the following details from the DB2 database:
           1. The DB2 host/IP - This destination should be accessible from the machine where you are doing the setup (running these scripts) as well as Bluemix Application where MobileFirst will eventually be deployed.
           2. The Database Name
           3. The Port on which the Database is setup
           4. The username - Make sure that the user has enough permissions to create tables in the Schema that is specified
           5. The password for the user
           6. The Schema name - Name of the schema to be used to create the MobileFirst specific tables. Make sure that the user specified has access to the schema mentioned. If the schema does not already exist, the user should have permissions to create the schema.
       NOTE: If the DB2 database is behind a firewall, you can connect to the DB2 database securely from Bluemix using the Secure Gateway service.


Step 2: Login to Bluemix and IBM Containers
-------------------------------------------
      # initenv.sh
          - The script logs into the container service. The script is a prerequisite to run any of the following scripts


Step 3: Setup the Server 
------------------------
	  a) Build the MobileFirst server image and upload to  IBM Container repository
          # prepareserver.sh
              - The script will build the MFP server and analytics images with the customizations done to  'usr-mfpf-server' and 'usr-mfpf-analytics' and pushes the images to the IBM Containers Service.
      
      b) Setup the databases for MobileFirst Platform
          # prepareserverdbs.sh 
              - This script configures the MFPF server with the database selected. The tables which are required by MobileFirst Platform are also created.
              
      c) Deploy MFP Server and Analytics on Docker containers using Kubernetes
         1. Set your terminal context to your cluster:
                    bx cs cluster-config my-cluster

            In the output, the path to your configuration file is displayed as a command to set an environment variable, for example:

                    export KUBECONFIG=/Users/ibm/.bluemix/plugins/container-service/clusters/my-cluster/kube-config-prod-dal12-my-cluster.yml

            Copy and paste the command to set the environment variable in your terminal and press Enter.

         2. [Mandatory for MFP Analytics] Create a Persistent Volume Claim. This will be used to persist Analyitics Data. 
            This is a one time step. You can reuse the PVC if you have already created it before.
            Review the yaml file args/mfpf-persistent-volume-claim.yaml and then run the command.

                    kubectl create -f ./args/mfpf-persistent-volume-claim.yaml

         3. Create the Kubernetes Deployments
            Edit the yaml file args/mfpf-deployment-all.yaml, and fill the details.
            Specifically, all entries in-between < and > are to be filled before executing the kubectl command.

            ./args/mfpf-deployment-all.yaml contains the deployment for the following:
            - A kubernetes deployment for MFP Server consisting of 3 instances (replicas), of 1024MB memory and 1Core CPU
            - A kubernetes deployment for MFP Analytics consisting of 2 instances (replicas), of 1024MB memory and 1Core CPU
            - A kubernetes service for MFP Server
            - A kubernetes service for MFP Analytics
            - An ingress for the whole setup including all the REST endpints for MFP Server and Analytics
            - A configMap to make the environment variables available in the MFP Server and Analytics instances

            Execute the following command:

                    kubectl create -f ./args/mfpf-deployment-all.yaml

            NOTE:
               The following template yaml files are supplied:
               - mfpf-deployment-all.yaml: Deploys the MFP Server and the Analytics server, with http.
               - mfpf-deployment-all-tls.yaml: Deploys the MFP Server and the Analytics server with https.
               - mfpf-deployment-server.yaml: Deploys the MFP Server with http.
               - mfpf-deployment-analytics.yaml: Deploys the MFP Analytics with http.
               
               
            After creation, to use the Kubernetes UI, execute the following command
                   kubectl proxy 
            Open your localhost:8001/ui in your browser 
            
----------------------------------------------------------------------------
Section 2: Instructions to setup IBM MobileFirst Platform Application Center 
----------------------------------------------------------------------------
	  a) Build the MobileFirst Application Center image and upload to  IBM Container repository
          # prepareappcenter.sh
              - The script will build the Application Center image with the customizations done to  'usr-mfp-appcenter' and pushes the images to the IBM Containers Service.
      
      b) Setup the databases for MobileFirst Platform Application Center
          # prepareappcenterdbs.sh 
              - This script configures the Application Center with the database selected. The tables which are required by Application Center are also created.
              
      c) Deploy MobileFirst Application Center on Docker containers using Kubernetes
         1. Set your terminal context to your cluster:
                    bx cs cluster-config my-cluster

            In the output, the path to your configuration file is displayed as a command to set an environment variable, for example:

                    export KUBECONFIG=/Users/ibm/.bluemix/plugins/container-service/clusters/my-cluster/kube-config-prod-dal12-my-cluster.yml

            Copy and paste the command to set the environment variable in your terminal and press Enter.

         2. Create the Kubernetes Deployments
            Edit the yaml file args/mfp-deployment-appcenter.yaml, and fill the details.
            Specifically, all entries in-between < and > are to be filled before executing the kubectl command.

            ./args/mfp-deployment-appcenter.yaml contains the deployment for the following:
            - A kubernetes deployment for Application Center consisting of 1 instances (replicas), of 1024MB memory and 1Core CPU
            - A kubernetes service for Application Center
            - An ingress for the whole setup including all the REST endpints for Application Center
            - A configMap to make the environment variables available in the Application Center

            Execute the following command:

                    kubectl create -f ./args/mfp-deployment-appcenter.yaml

            NOTE:
               The following template yaml files are supplied:
               - mfp-deployment-appcenter.yaml: Deploys the Application Center, with http.
               - mfp-deployment-appcenter-with-tls.yaml: Deploys the Application Center with https.
               - mfp-deployment-lite-appcenter.yaml: Deploys the Application Center with http on free cluster.
               
            After creation, to use the Kubernetes UI, execute the following command
                   kubectl proxy 
            Open your localhost:8001/ui in your browser 
        
