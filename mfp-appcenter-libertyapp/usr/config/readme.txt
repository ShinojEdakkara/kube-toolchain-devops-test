This folder contains the server configuration fragments (keystore, server properties, user registry) used by MobileFirst Platform Application Center.

   i) keystore.xml - the configuration of the repository of security certificates used for SSL encryption. The files listed must be referenced in the ./usr/security folder.
  ii) registry.xml - user registry configuration. The basicRegistry (a basic XML-based user-registry configuration) is provided as the default. User names and passwords can be configured for basicRegistry or you can configure ldapRegistry.
  For more information on Configuring user authentication for Application Center please refer https://mobilefirstplatform.ibmcloud.com/tutorials/en/foundation/8.0/installation-configuration/production/appcenter/#configuring-user-authentication-for-application-center
  iii) tracespce.xml - for configuring the traces
   iv) Your database configuration files will be stored in this directory after you run the prepareserverdbs.sh script.