All scripts in the /scripts folder support the following methods for passing-in the required parameters: 
1. Command-line arguments 
2. From file (See args/ folder for related .properties files)
3. Interactively when you run the script with no arguments.

The usage / help of every script can be obtained by using the -h or --help command line arguments
Step 1: Prerequisite: Create a database for MobileFirst Application Center data
------------------------------------------------------------
   A Bluemix Service
   ---------------------------
       Create a Bluemix service for the database that will be used by MobileFirst Appication Center.
       Supported database services are : dashDB For Transactions service or dashDB service (Transactional plans only)

       Alternatively, you can use the following cf commands:
       a) Login to Bluemix:
          # cf login
       b) Create the service of your choice. Choose the right service-type & service-plan.  Supported service-type, service-plan combinations are :
                 i) dashDB For Transactions & any plan
                ii) dashDB &  Any Enterprise Transactional(OLTP) plan. For ex. EnterpriseTransactional2.8.500, EnterpriseTransactional12.128.1400 
                
          # cf create-service <bluemix-service-type> <bluemix-service-plan> <bluemix-service-name>
       Note: Some of the plans of dashDB service are instant activation. For other service plans, you may need to contact the sales team to order the service instance


Step 2: Login to Bluemix
------------------------
   # initenv.sh
       - The script logs into BLuemix. The script is a prerequisite to run any of the following scripts


Step 3: Setup the MobileFirst Application Center 
------------------------------------
   a) Setup the databases for MobileFirst Platform
       # prepareappcenterdbs.sh 
           - This script configures the MFP ApplicationCenter with the database selected. The tables which are required by MobileFirst Platform Application Center are also created.
   b) Build the MobileFirst application center app and upload to IBM Bluemix
       # prepareappcenter.sh
           - The script will build the application center app with the customizations done to the 'mfp-appcenter' and pushes the app to IBM Bluemix.
   c) Start the Liberty for java app with MobileFirst Platform Application Center
       # startappcenter.sh 
           - Run the script startappcenter.sh to start the app
  
