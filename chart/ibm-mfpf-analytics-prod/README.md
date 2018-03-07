# MobileFirst Foundation Analytics Helm Chart
IBM MobileFirst™ Analytics gives a rich view into both your mobile landscape and server infrastructure. Included are default reports of user retention, crash reports, device type and operating system breakdowns, custom data and custom charts, network usage, push notification results, in-app behavior, debug log collection, and beyond.

For more information: [MobileFirst Operational Analytics Documentation](https://www.ibm.com/support/knowledgecenter/en/SSHS8R_8.0.0/com.ibm.worklight.analytics.doc/analytics/c_introduction.html)
## Prerequisites

1. (Mandatory) PersistentVolume needs to be pre-created prior to installing the chart if `persistance.enabled=true` and `persistence.dynamicProvisioning=false` (default values, see [persistence](#persistence) section). It can be created by using the IBM Cloud Private UI or via a yaml file as the following example:
The PVC will be used to store analytics data.

```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: <persistent volume name>
spec:
  capacity:
    storage: 20Gi
  accessModes:
    - ReadWriteMany
  hostPath:
    path: <PATH>
```

2. (Optional) You can provide your own keystore and truststore to the deployment by creating a secret with your own keystore and truststore.

Pre-create a secret with keystore.jks, keystore-password.txt, truststore.jks, truststore-password.txt and provide the secret name in the field keystores.keystoresSecretName.

Keep the files keystore.jks and its password in a file named keystore-password.txt, truststore.jks and its password in a file named truststore-password.jks. 
From the command line, execute:
*      `kubectl create secret generic mfpf-cert-secret --from-file keystore-password.txt --from-file truststore-password.txt --from-file keystore.jks --from-file truststore.jks`

Note that the names of the files should be the same as mentioned here: keystore.jks,keystore-password.txt, truststore.jks and truststore-password.txt.

Provide this secret name in keystoresSecretName, and overide the default keystores.
## Accessing MobileFirst Analytics

From a browser, use *external_ip:nodeport/analytics/console* to access MobileFirst Operational Analytics console.  
Get the Analytics URL by running these commands:  
 1. If you need to use https port:  
   ```
   export NODE_IP=$(kubectl get nodes --namespace {{ .Release.Namespace }} \
          -o jsonpath="{.items[0].status.addresses[0].address}")
   export NODE_PORT=$(kubectl get --namespace {{ .Release.Namespace }} \
          -o jsonpath="{.spec.ports[1].nodePort}" services {{ template "fullname" . }})
   echo https://$NODE_IP:$NODE_PORT/analytics/console
   ```
 2. If you need to use http port:  
   ```
   export NODE_IP=$(kubectl get nodes --namespace {{ .Release.Namespace }} \
          -o jsonpath="{.items[0].status.addresses[0].address}")  
   export NODE_PORT=$(kubectl get --namespace {{ .Release.Namespace }} \
          -o jsonpath="{.spec.ports[0].nodePort}" services {{ template "fullname" . }})  
   echo http://$NODE_IP:$NODE_PORT/analytics/console
   ```

NOTE: The Port number 9600 is exposed internally in the Kubernetes service. This is used by the MobileFirst Analytics instances as the transport port 

### Parameters

| Qualifier | Parameter  | Definition | Allowed Value |
|---|---|---|---|
| arch     |      | Worker node architecture | Worker node architecture to which this chart should be deployed. Only AMD64 platform is currently supported |
| image     | pullPolicy | Image Pull Policy | Always, Never, or IfNotPresent. Default: IfNotPresent |
|           | name          | Docker image name | Name of the MobileFirst Operational Analytics docker image |
|           | tag          | Docker image tag | See Docker tag description |
| scaling | replicaCount | The number of instances (pods) of MobileFirst Operational Analytics that need to be created | Positive integer (Default: 2) |
| mobileFirstAnalyticsConsole | user | Username for MobileFirst Operational Analytics | Default: admin |
|                       | password | Password for MobileFirst Operational Analytics | Default: admin |
|  analyticsConfiguration | clusterName | Name of the MobileFirst Analytics cluster. | defaults to "mobilefirst"|
|                       | numberOfShards | Number of Elasticsearch shards for MobileFirst Analytics | default to 2|             
|                       | replicasPerShard | Number of Elasticsearch replicas to be maintained per each shard for MobileFirst Analytics | default to 2|             
|                          | analyticsDataDirectory | Path where analytics data is stored. ( It will also be the same path where the persistent volume claim is mounted inside the container) | defaults to "/analyticsData"|
| keystores | keystoresSecretName | Refer the configuration section to pre-create the secret with keystores and their passwords.|
| jndiConfigurations | mfpfProperties | MobileFirst JNDI properties to be specified to customize operational analytics| Supply comma separated name value pairs  |
| ingress | enabled | Enable ingress | Default: false |
|         | sslSecretName | Ingress SSL Certificate Secret name (Optional) | If you need to expose your ingress endpoint over SSL, create a secret with the certificate and provide the name of the secret here. Required if you need to use the ingress endpoint over SSL. See the readme for creating the secret |
| resources | limits.cpu  | Describes the maximum amount of CPU allowed.  | Default is 2000m. See Kubernetes - [meaning of CPU](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/#meaning-of-cpu) |
|                  | limits.memory | Describes the maximum amount of memory allowed. | Default is 4096Mi. See Kubernetes - [meaning of Memory](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/#meaning-of-memory)|
|           | requests.cpu  | Describes the minimum amount of CPU required - if not specified will default to limit (if specified) or otherwise implementation-defined value.  | Default is 1000m. See Kubernetes - [meaning of CPU](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/#meaning-of-cpu) |
|           | requests.memory | Describes the minimum amount of memory required. If not specified, the memory amount will default to the limit (if specified) or the implementation-defined value. | Default is 2048Mi. See Kubernetes - [meaning of Memory](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/#meaning-of-memory) |
| persistence | enabled         | Use a PVC to persist data                        | true                                                     |
|            |useDynamicProvisioning      | Specify a storageclass or leave empty  | false                                                    |
| dataVolume|existingClaimName| Provide an existing PersistentVolumeClaim          | nil                                                      |
|           |storageClass     | Storage class of backing PVC                       | nil                                                      |
|           |size             | Size of data volume                                | 20Gi                                                     |



