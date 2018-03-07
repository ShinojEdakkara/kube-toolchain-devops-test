# MobileFirst Foundation Server Helm Chart
IBM MobileFirst™ Platform Foundation is an integrated platform that helps you extend your business to mobile devices.

IBM MobileFirst Platform Foundation includes a comprehensive development environment, mobile-optimized runtime middleware, a private enterprise application store, and an integrated management and analytics console, all supported by various security mechanisms.

For more information: [MobileFirst Server Documentation](https://www.ibm.com/support/knowledgecenter/en/SSNJXP/welcome.html)
## Prerequisites

1. (Mandatory) A pre-configured DB2 database is required and this information will be supplied to server helm chart to create appropriate tables for Server.

2. (Optional) You can provide your own keystore and truststore to the deployment by creating a secret with your own keystore and truststore.

Pre-create a secret with keystore.jks, keystore-password.txt, truststore.jks, truststore-password.txt and provide the secret name in the field keystores.keystoresSecretName.

Keep the files keystore.jks and its password in a file named keystore-password.txt, truststore.jks and its password in a file named truststore-password.jks.  
From the command line, execute:
*    `kubectl create secret generic mfpf-cert-secret --from-file keystore-password.txt --from-file truststore-password.txt --from-file keystore.jks --from-file truststore.jks`

Note that the names of the files should be the same as mentioned here: keystore.jks,keystore-password.txt, truststore.jks and truststore-password.txt.

Provide this secret name in keystoresSecretName to overide the default keystores.

If you plan to connect MobileFirst Server to Operational Analytics, then use the helm chart for MobileFirst Operational Analytics to create it first, before creating the Server.

## Accessing MobileFirst Server
From a browser, use *external_ip:nodeport/mfpconsole* to access  Mobile Foundation Operations Console.

Get the Server URL by running these commands:  
 1. If you need to use https port:
   ```
   export NODE_IP=$(kubectl get nodes --namespace {{ .Release.Namespace }} \
          -o jsonpath="{.items[0].status.addresses[0].address}")
   export NODE_PORT=$(kubectl get --namespace {{ .Release.Namespace }} \
          -o jsonpath="{.spec.ports[1].nodePort}" services {{ template "fullname" . }})
   echo https://$NODE_IP:$NODE_PORT/mfpconsole
   ```
 2. If you need to use http port:  
   ```
   export NODE_IP=$(kubectl get nodes --namespace {{ .Release.Namespace }} \
          -o jsonpath="{.items[0].status.addresses[0].address}")  
   export NODE_PORT=$(kubectl get --namespace {{ .Release.Namespace }} \
          -o jsonpath="{.spec.ports[0].nodePort}" services {{ template "fullname" . }})  
   echo http://$NODE_IP:$NODE_PORT/mfpconsole
   ```

### Parameters

| Qualifier | Parameter  | Definition | Allowed Value |
|---|---|---|---|
| arch     |      | Worker node architecture | Worker node architecture to which this chart should be deployed. Only AMD64 platform is currently supported |
| image     | pullPolicy | Image Pull Policy | Always, Never, or IfNotPresent. Default: IfNotPresent |
|           | name          | Docker image name | Name of the MobileFirst Server docker image |
|           | tag          | Docker image tag | See Docker tag description |
| scaling | replicaCount | The number of instances (pods) of MobileFirst Server that need to be created | Positive integer (Default: 3) |
| mobileFirstOperationsConsole | user | Username of the MobileFirst Server | Default: admin |
|                       | password | password of the MobileFirst Server | Default: admin |
|  existingDB2Details | db2Host | IP Address or HOST of the DB2 Database where MobileFirst Server tables need to be configured. | Only DB2 is supported. |
|                       | db2Port | 	Port where DB2 database is setup | |             
|                       | db2Database | Name of the database that is pre-configured in DB2 for use| |
|                       | db2Username  | DB2 User name to access the DB2 database | User should have access to create tables, and create schema if it does not already exist |
|                       | db2Password | DB2 password for the database supplied. | |
|                       | db2Schema | Server db2 schema to be created. | If the schema already present, it will be used. Otherwise, it will be created. |
|                       | db2ConnectionIsSSL | DB2 Connection type  | Specify if you Database connection has to be http or https. Default value is false (http). Make sure that the DB2 port is also configured for the same connection mode |
| existingMobileFirstAnalytics | analyticsEndpoint | URL of the analytics server. | For Ex. http://9.9.9.9:30400 . Do not specify the path to the console - it will be added during deployment|
|                       | analyticsAdminUser | Username of the analytics admin user | |
|                       | analyticsAdminPassword | Password of the analytics admin user | |
| keystores | keystoresSecretName | Refer the configuration section to pre-create the secret with keystores and their passwords.|
| jndiConfigurations | mfpfProperties | MobileFirst Server JNDI properties to customize deployment | Supply comma separated name value pairs |
| ingress | enabled | Enable ingress | Default: false |
|         | sslSecretName | Ingress SSL Certificate Secret name (Optional) | If you need to expose your ingress endpoint over SSL, create a secret with the certificate and provide the name of the secret here. Required if you need to use the ingress endpoint over SSL. See the readme for creating the secret |
| resources | limits.cpu  | Describes the maximum amount of CPU allowed.  | Default is 2000m. See Kubernetes - [meaning of CPU](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/#meaning-of-cpu) |
|                  | limits.memory | Describes the maximum amount of memory allowed. | Default is 4096Mi. See Kubernetes - [meaning of Memory](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/#meaning-of-memory)|
|           | requests.cpu  | Describes the minimum amount of CPU required - if not specified will default to limit (if specified) or otherwise implementation-defined value.  | Default is 1000m. See Kubernetes - [meaning of CPU](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/#meaning-of-cpu) |
|           | requests.memory | Describes the minimum amount of memory required. If not specified, the memory amount will default to the limit (if specified) or the implementation-defined value. | Default is 2048Mi. See Kubernetes - [meaning of Memory](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/#meaning-of-memory) |


