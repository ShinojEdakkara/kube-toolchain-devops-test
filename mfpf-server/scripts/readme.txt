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
      a) Setup the databases for MobileFirst Platform
          # prepareserverdbs.sh 
              - This script configures the MFPF server with the database selected. The tables which are required by MobileFirst Platform are also created.
      b) Build the MobileFirst server image and upload to  IBM Container repository
          # prepareserver.sh
              - The script will build the sever image with the customizations done to the 'mfpf-server' and pushes the image to the IBM Containers Service.
      c) Start an IBM Container with MobileFirst Platform
          Option i) 
              # startserver.sh 
                  - Run the script startserver.sh to run the server image as a Stand-alone container
          Option ii)
              # startservergroup.sh 
                  - Run the script startservergroup.sh to run the server image as a Container group
