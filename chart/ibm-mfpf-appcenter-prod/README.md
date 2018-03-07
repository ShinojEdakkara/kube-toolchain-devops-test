# MobileFirst Foundation Application Center Helm Chart
Application Center can be used as an Enterprise application store and is a means of sharing information among different team members within a company.
The concept of Application Center is similar to the concept of the Apple public App Store or the Android Market, except that it targets only private usage within a company.
By using Application Center, users from the same company or organization download applications to mobile phones or tablets from a single place that serves as a repository of mobile applications.

For more information: [MobileFirst Application Center Documentation](https://www.ibm.com/support/knowledgecenter/en/SSHS8R_8.0.0/com.ibm.worklight.appcenter.doc/appcenter/c_intro_appcenter.html)
## Prerequisites

1. (Mandatory) A pre-configured DB2 database is required and this information will be supplied to appcenter helm chart to create appropriate tables for Application center.

2. (Optional) You can provide your own keystore and truststore to the deployment by creating a secret with your own keystore and truststore.

Pre-create a secret with keystore.jks, keystore-password.txt, truststore.jks, truststore-password.txt and provide the secret name in the field keystores.keystoresSecretName.

Keep the files keystore.jks and its password in a file named keystore-password.txt, truststore.jks and its password in a file named truststore-password.jks.
From the command line, execute:
*    `kubectl create secret generic mfpf-cert-secret --from-file keystore-password.txt --from-file truststore-password.txt --from-file keystore.jks --from-file truststore.jks`

Note that the names of the files should be the same as mentioned here: keystore.jks,keystore-password.txt, truststore.jks and truststore-password.txt.

Provide this secret name in keystoresSecretName to overide the default keystores.


## Accessing Application Center

From a browser, use *external_ip:nodeport/appcenterconsole* to access the Application Center console.

Get the Application Center URL by running these commands:  

 1. If you need to use https port:
   ```
   export NODE_IP=$(kubectl get nodes --namespace {{ .Release.Namespace }} \
          -o jsonpath="{.items[0].status.addresses[0].address}")
   export NODE_PORT=$(kubectl get --namespace {{ .Release.Namespace }} \
          -o jsonpath="{.spec.ports[1].nodePort}" services {{ template "fullname" . }})
   echo https://$NODE_IP:$NODE_PORT/appcenterconsole
   ```
 2. If you need to use http port:  
   ```
   export NODE_IP=$(kubectl get nodes --namespace {{ .Release.Namespace }} \
          -o jsonpath="{.items[0].status.addresses[0].address}")  
   export NODE_PORT=$(kubectl get --namespace {{ .Release.Namespace }} \
          -o jsonpath="{.spec.ports[0].nodePort}" services {{ template "fullname" . }})  
   echo http://$NODE_IP:$NODE_PORT/appcenterconsole
   ```


### Parameters

| Qualifier | Parameter  | Definition | Allowed Value |
|---|---|---|---|
| arch     |      | Worker node architecture | Worker node architecture to which this chart should be deployed. Only AMD64 platform is currently supported |
| image     | pullPolicy | Image Pull Policy |Always, Never, or IfNotPresent. Default: IfNotPresent.  |
|           | name          | Docker image name | Name of the MobileFirst Application Center docker image |
|           | tag          | Docker image tag | See Docker tag description |
| mobileFirstAppCenterConsole | user | Username of the Application center console | |
|                       | password | password of the Application center console | |
|  existingDB2Details | appCenterDB2Host | IP Address of the DB2 Database where Appcenter database needs to be configured	| |
|                       | appCenterDB2Port | 	Port of the DB2 database is setup | |             
|                       | appCenterDB2Database | Name of the database to be used | The database has to be precreated.|
|                       | appCenterDB2Username  | DB2 Username to access the DB2 database | User should have access to create tables, and create schema if it does not already exist |
|                       | appCenterDB2Password | DB2 password for the database supplied. | |
|                       | appCenterDB2Schema | Application Center db2 schema to be created. | If the schema already exists, it will be used. If not, one will be created. |
|                       | appCenterDB2ConnectionIsSSL |DB2 Connection type  | Specify if you Database connection has to be http or https. Default value is false (http). Make sure that the DB2 port is also configured for the same connection mode |
| keystores | keystoresSecretName | Refer the configuration section to pre-create the secret with keystores and their passwords.|
| ingress | enabled | Enable ingress | Default: false |
|         | sslSecretName | Ingress SSL Certificate Secret name (Optional) | If you need to expose your ingress endpoint over SSL, create a secret with the certificate and provide the name of the secret here. Required if you need to use the ingress endpoint over SSL. See the readme for creating the secret |
| resources | limits.cpu  | Describes the maximum amount of CPU allowed.  | Default is 1000m. See Kubernetes - [meaning of CPU](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/#meaning-of-cpu) |
|                  | limits.memory | Describes the maximum amount of memory allowed. | Default is 1024Mi. See Kubernetes - [meaning of Memory](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/#meaning-of-memory)|
|           | requests.cpu  | Describes the minimum amount of CPU required - if not specified will default to limit (if specified) or otherwise implementation-defined value.  | Default is 1000m. See Kubernetes - [meaning of CPU](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/#meaning-of-cpu) |
|           | requests.memory | Describes the minimum amount of memory required. If not specified, the memory amount will default to the limit (if specified) or the implementation-defined value. | Default is 1024Mi. See Kubernetes - [meaning of Memory](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/#meaning-of-memory) |

