
IBM Transformation Extender Advanced v10.0.1.8

## What's New

- EVERYTHING!

## Checklist

- Use below checklist before launching the ITXA applications
1. Push all images from box into your openshift registry.
2. It is recommended to install ITXA and B2BI in the same namespace.  If not you have to duplicate the PV and create separate PVCs in each namespace.
2. Create itxa persistent volume claim using the sample pvc below.  This should automatically create the PV using your default storage class.  Make sure your default storage class is using some flavor if IBM File storage and not IBM Block as this volume will be shared between the B2BI and ITXA pods, so must have RWX access.
3. Create Secrets per instructions below. This includes DB secret, TLS secret, user secret.
4. Create Role, RBAC, Pod Security Policy, Cluster Role and Cluster Rolebinding, and Security Context Constraint.
2. JDBC driver Jar is uploaded in Cloud Object Store or added to image.  If using COS in IBM Cloud, make sure to create HMAC credentials to get accesskey and secretkey.
3. Charts downloaded and fields in values.yaml are populated.
    1.  Set License to true.
    2.  Add proper images and tags and pull secret for your repo (if any)
    3.  Add proper secret names to match the secrets you created.
4. Create Busybox deployment and set proper access on ITXA file share.  This is a hack that will be fixed by GA.
    1.  Create a busybox deployment using the yaml I'll send you.
    2.  Check the yaml to make sure the yaml is mounting the pvc name that you are using for the itxa common pvc and it's pulling from the proper registry.  You can pull busybox directly from dockerhub or pull it down and push it to your OCP registry.
    3.  create the deployment using oc create -f busybox3.yaml
    4.  This will create the deployment, but it will not deploy a pod due to incompatible security settings.  That's fine.  It doesn't matter.
    5.  Deploy a debug pod with root access based on the busybox deployment.  `oc debug busybox --as-root -n <project_name>`
    6.  Once the container comes up, open the terminal for it, change to /vtest which will be mounted to the PV and change permissions.
        - `chown -R 1001 /[mounted dir]`
        - `chgrp -R 0 /[mounted dir]`
        - `chmod -R 770 /[mounted dir]`
        Note you only have to do this once unless you delete and recreate the volume.  Once the permissions are set properly they won't need to be touched again if you uninstall and reinstall the chart.

5. Run helm install pointing to the values.yaml you've been editing.  When installing for the first time, set the itxui install to false, dbinit to true, and the packs to false.
```
 install:
  itxaUI:
    enabled: false
  itxadbinit:
    enabled: true
```
   The DB init process will take awhile if it works.  Continue once it finishes.
6. Run helm upgrade, but this time with the itxadbinit to false and the itxui enabled.
   ```
   install:
   itxaUI:
    enabled: true
   itxadbinit:
    enabled: false
    ```
   Verify the ITXA UI pod comes up and you can connect to it.

7. Once ITXUI is up, Set DB init to true and packs to true and run helm upgrade again to install packs.  This should spin back up the dbinit container and spend some time deploying packs.  Check logs to make sure it works.
8. Once Packs are installed, delete UI POD so it redeploys to pick up packs.

## Prerequisites for ITXA


## Installing the Chart (Installing the ITXA UI Server)

Prepare a custom values.yaml file based on the configuration section. Ensure that application license is accepted by setting the value of `global.license` to true.

Note:

1. All the section in values.yaml like global, itxauiserver, itxadatasetup and metering need to be populated before installing ITXA UI Server.


### Helm Install

### Install repository (Below content explains how to install the repository on a NFS server.)

Make sure you have set the permissions on the repository correctly.
You can do that by mounting the above folder into a node and execute below cmds.

- `sudo chown -R 1001 /[mounted dir]`
- `sudo chgrp -R 0 /[mounted dir]`
- `sudo chmod -R 770 /[mounted dir]`

The above cmds make sure the repository folders and files have right permissions for the pods to access them.
As noted the owner of the files in folders is the user 1001 and group as root.
Also the rwx permissions are 770.

### Identify Sub Domain Name of your cluster

- Steps to find Sub Domain Name. You would need this information when you need to provide a hostname to provide to ingress and in sign-in certificates.
  Taking an eg of a cluster web console URL - `https://console-openshift-console.apps.somename.os.mycompany.com`
  1. Identify the cluster name in the console URL, for eg somename is the cluster name.
  2. Identify the base domain which is placed after the cluster name. In above the base domain is os.mycompany.com.
  3. So sub domain name is derived as - apps.<cluster name>.<base domain> i.e. apps.somename.os.mycompany.com

### Install Persistent related objects in Openshift - (Below are example files used to create Persistent Volume and related object using NFS server.)

- Note - The charts are bundled with sample files as templates , you can use these to plugin in your configuration and
  create pre-req objects. They are packaged in prereqs.zip along with the chart.

1. Download the charts from IBM site.
2. Create a persistent volume , persistent volume claim and storage class with access mode as 'Read write many' with minimum 12GB space.


- Create persistent volume claim , itxa_pvc.yaml file as below -

```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: itxa-nfs-claim
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 5Gi
  storageClassName: itxa-sc
  volumeName: itxa-pv
```

`oc create -f itxa_pvc.yaml`

- Create a Database secret, file itxa-secrets.yaml as below -

```
apiVersion: v1
kind: Secret
metadata:
  name: itxa-secrets
type: Opaque
stringData:
  dbUser: xxxx
  dbPassword: xxxx
  dbHostIp: "1.2.3.4"
  databaseName: dbname
  dbPort: "50000"
```

`oc create -f itxa-secrets.yaml`

3. Create a secret tls-itxa-secret.yaml with a password for Liberty Keystore pkcs12.

```
apiVersion: v1
kind: Secret
metadata:
  name: tls-itxa-secret
type: Opaque
stringData:
  tlskeystorepassword: [tlskeystore password]
```

`oc create -f tls-itxa-secret.yaml`
Password can be anything, it will be used by Libterty for keystore access.
You will need to mention this secret name in Values.global.tlskeystoresecret field.

4. If you choose to create a self signed certificate for ingress, please follow below steps.
   Create certificate and key for ingress - ingress.crt and key ingress.key
   This is for create cert for ingress object to enable https for ITXA.
   Prereq is to select a ingress host for launching ITXA.

e.g. ingress host your machine specific.
Pleae note the ingress host should end in the subdomain name of your machine.

cmd -
`openssl req -x509 -nodes -days 365 -newkey ./ingress.key -out ingress.crt -subj "/CN=[ingress_host]/O=[ingress_host]"`

cmd -
`oc create secret tls itxa-ingress-secret --key ingress.key --cert ingress.crt`

- You need to refer this secret name into values.yaml - itxauiserver.ingress.ssl.secretname
- Also enable ssl by setting itxauiserver.ingress.ssl.enabled to true.

For **production environments** it is strongly recommended to obtain a CA certified TLS certificate and create a secret manually as below.

1.  Obtain a CA certified TLS certificate for the given `itxauiserver.ingress.host` in the form of key and certificate files.
2.  Create a secret from the above key and certificate files by running below command

```
	oc create secret tls <release-name>-ingress-secret --key <file containing key> --cert <file containing certificate> -n <namespace>
```

3.  Use the above created secret as the value of the parameter `itxauiserver.ingress.ssl.secretname`.

4.  Set the following variables in the values.yaml
    1. Set the Registry from where you will pull the images-
       e.g. global.image.repository: "cp.icr.io/ibm-itxa"
    2. Set the image names -
       e.g. itxauiserver.image.name: itxa-ui-server
       e.g. itxauiserver.image.tag: 10.0.1.7_APR_04_04_6
    3. Set the ingress host
       - Note: The ingress host should end in same subdomain as the cluster node.
    4. Check global.persistence.claims.name “itxa-nfs-claim” matches with name given in pvc.yaml.
    5. Check the ingress tls secret name is set correctly as per cert created above, in place of itxauiserver.ingress.ssl.secretname

### Steps to set a default Password

1. Before installing ITXA UI Server create a secret file `itxa-user-secret.yaml`.

Example: Replace <ADMIN_USER_PASSWORD> with password

```
apiVersion: v1
kind: Secret
metadata:
  name: "<secrets_name>"
type: Opaque
stringData:
  adminPassword: "<ADMIN_USER_PASSWORD>"
```

2.  Create secret using following command

    ```
    kubectl create -f itxa-user-secret.yaml
    ```

3.  Provide the secret name in values.yaml in itxauiserver section against the field userSecret
    Example

    ```
    itxauiserver:
      --------------
      --------------
      userSecret: "itxa-user-secret"
    ```

4.  Once ITXA UI Server is installed the user can login to application using the admin password provided in the secret file.

**Note** : It is mandatory to create itxa-user-secret.yaml and set default password.

### To install the chart with the release name `my-release` via cmd line:

1. Ensure that the chart is downloaded locally by following the instructions given.
2. Set up which application you need to install.
   Decide which application you need to install and set the 'enabled' flag to true for it, in the values.yaml file.
   Preferred way is to install one application at a time. Hence you will need to disable the flag for the application once already installed.

```
 install:
  itxaUI:
    enabled: false
  itxadbinit:
    enabled: false
```

3. Check the settings are good in values.yaml by simulating the install chart.
   cmd - helm template --name=my-release [chartpath]
   This should give you all kubernetes objects which would be getting deployed on Openshift.
   This cmd won't actually install kubernetes objects.
4. To run Database Initialization script run below command

```
helm install my-release [chartpath] --timeout 3600 --set global.license=true, global.install.itxaUI.enabled=false, global.install.itxadbinit.enabled=true
```

5. Similarly to install ITXA UI Application run below command

```
helm install my-release [chartpath] --timeout 3600 --set global.license=true, global.install.itxaUI.enabled=true, global.install.itxadbinit.enabled=false
```

6. Test the installation -

ITXA UI Login - https://[hostname]/spe/myspe

Depending on the capacity of the kubernetes worker node and database connectivity, the whole deploy process can take on average

- 1-2 minutes for 'installation against a pre-loaded database' and
- 15-20 minutes for 'installation against a fresh new database'

When you check the deployment status, the following values can be seen in the Status column:
– Running: This container is started.
– Init: 0/1: This container is pending on another container to start.

You may see the following values in the Ready column:
– 0/1: This container is started but the application is not yet ready.
– 1/1: This application is ready to use.

Run the following command to make sure there are no errors in the log file:

```
oc logs <pod_name> -n <namespace> -f
```

7. If you are deploying IBM Sterling Transformation Extender Advanced on a namespace other than default, then create a Role Based Access Control(RBAC) if not already created, with cluster admin role.

- The following is an example of the RBAC for default service account on target namespace as `<namespace>`.

```
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: itxa-role-<namespace>
  namespace: <namespace>
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "watch", "list","create","delete","patch","update"]

---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: itxa-rolebinding-<namespace>
  namespace: <namespace>
subjects:
- kind: ServiceAccount
  name: default
  namespace: <namespace>
roleRef:
  kind: Role
  name: itxa-role-<namespace>
  apiGroup: rbac.authorization.k8s.io


```

## PodSecurityPolicy Requirements

In case you need a PodSecurityPolicy to be bound to the target namespace follow below steps. Choose either a predefined PodSecurityPolicy or have your cluster administrator create a custom PodSecurityPolicy for you:

- ICPv3.1 - Predefined PodSecurityPolicy name: [`default`](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_3.1.0/manage_cluster/enable_pod_security.html)
- ICPv3.1.1 - Predefined PodSecurityPolicy name: [`ibm-anyuid-psp`](https://ibm.biz/cpkspec-psp)

- Custom PodSecurityPolicy definition:

```
apiVersion: apps/v1
kind: PodSecurityPolicy
metadata:
  annotations:
    kubernetes.io/description: "This policy allows pods to run with
      any UID and GID, but preventing access to the host."
  name: ibm-itxa-anyuid-psp
spec:
  allowPrivilegeEscalation: true
  fsGroup:
    rule: RunAsAny
  requiredDropCapabilities:
  - MKNOD
  allowedCapabilities:
  - SETPCAP
  - AUDIT_WRITE
  - CHOWN
  - NET_RAW
  - DAC_OVERRIDE
  - FOWNER
  - FSETID
  - KILL
  - SETUID
  - SETGID
  - NET_BIND_SERVICE
  - SYS_CHROOT
  - SETFCAP
  runAsUser:
    rule: RunAsAny
  seLinux:
    rule: RunAsAny
  supplementalGroups:
    rule: RunAsAny
  volumes:
  - configMap
  - emptyDir
  - projected
  - secret
  - downwardAPI
  - persistentVolumeClaim
  forbiddenSysctls:
  - '*'
```

To create a custom PodSecurityPolicy, create a file `itxa_psp.yaml` with the above definition and run the below command

```
oc create -f itxa_psp.yaml
```

- Custom ClusterRole and RoleBinding definitions:

```
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  annotations:
  name: ibm-itxa-anyuid-clusterrole
rules:
- apiGroups:
  - extensions
  resourceNames:
  - ibm-itxa-anyuid-psp
  resources:
  - podsecuritypolicies
  verbs:
  - use

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ibm-itxa-anyuid-clusterrole-rolebinding
  namespace: <namespace>
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: ibm-itxa-anyuid-clusterrole
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: system:serviceaccounts:<namespace>

```

The `<namespace>` in the above definition should be replaced with the namespace of the target environment.
To create a custom ClusterRole and RoleBinding, create a file `itxa_psp_role_and_binding.yaml` with the above definition and run the below command

```
oc create -f itxa_psp_role_and_binding.yaml
```

## Red Hat OpenShift SecurityContextConstraints Requirements

The Helm chart is verified with the predefined `SecurityContextConstraints` named [`ibm-anyuid-scc.`](https://ibm.biz/cpkspec-scc) Alternatively, you can use a custom `SecurityContextConstraints.` Ensure that you bind the `SecurityContextConstraints` resource to the target namespace prior to installation.

### SecurityContextConstraints Requirements

Custom SecurityContextConstraints definition:

```yaml
apiVersion: security.openshift.io/v1
kind: SecurityContextConstraints
metadata:
  annotations:
  name: ibm-itxa-scc
allowHostDirVolumePlugin: false
allowHostIPC: false
allowHostNetwork: false
allowHostPID: false
allowHostPorts: false
allowPrivilegedContainer: false
allowedCapabilities: []
allowedFlexVolumes: []
defaultAddCapabilities: []
fsGroup:
  type: MustRunAs
  ranges:
    - max: 65535
      min: 1
readOnlyRootFilesystem: false
requiredDropCapabilities:
  - ALL
runAsUser:
  type: MustRunAsRange
seccompProfiles:
  - docker/default
seLinuxContext:
  type: RunAsAny
supplementalGroups:
  type: MustRunAs
  ranges:
    - max: 65535
      min: 1
volumes:
  - configMap
  - downwardAPI
  - emptyDir
  - persistentVolumeClaim
  - projected
  - secret
priority: 0
```

To create a custom `SecurityContextConstraints`, create a yaml file with the custom `SecurityContextConstraints` definition and run the following command:

```sh
kubectl create -f <custom-scc.yaml>
```

## Configuration

### Ingress

- For ITXA UI Server Ingress can be enabled by setting the parameter `itxauiserver.ingress.enabled` as true. If ingress is enabled, then the application is exposed as a `ClusterIP` service, otherwise the application is exposed as `NodePort` service. It is recommended to enable and use ingress for accessing the application from outside the cluster. For production workloads, the only recommended approach is Ingress with cluster ip. Do not use NodePort.

- `itxauiserver.ingress.host` - the fully-qualified domain name that resolves to the IP address of your cluster’s proxy node. Based on your network settings it may be possible that multiple virtual domain names resolve to the same IP address of the proxy node. Any of those domain names can be used. For example "example.com" or "test.example.com" etc.

#### Uploading of Database Driver.

1. Depending upon the Database the Customer uses the respective JDBC Jar need to be uploaded either in S3 Object or Need to be stored in NFS Share.
2. IF Customer uploads Database driver in S3 Object. Then it is mandatory to provide accessKey and secretKey in itxa-secrets.yaml along with other DB Parameter.
3. In values.yaml in global section following details need to be provided
   database:
   dbvendor: <db_vendor>
   s3host: "<s3_host>"
   s3bucket: "<s3_bucket>"

### Installation of new database

This will create the required database tables and factory data in the database.

#### DB2 database secrets:

1. Create db2 database user.
2. Add following properties in `itxa-secrets.yaml` file.

```
apiVersion: v1
kind: Secret
metadata:
  name: <secrets_name>
type: Opaque
stringData:
  dbUser: <DB_USER>
  dbPassword: <DB_PASSWORD>
  dbHostIp: "<DB_HOST>"
  databaseName: <DATABASE_NAME>
  dbPort: "<DB_PORT>"
  accessKey: "<ACCESS_KEY>"
  secretKey: "<SECRET_KEY>"

```

3.  Create secret using following command
    ```
    oc create -f itxa-secrets.yaml
    ```

3. Add following properties in `itxa-secrets.yaml`

```
apiVersion: v1
kind: Secret
metadata:
  name: <secrets_name>
type: Opaque
stringData:
  dbUser: <DB_USER>
  dbPassword: <DB_PASSWORD>
  dbHostIp: "<DB_HOST>"
  databaseName: <DATABASE_NAME>
  dbPort: "<DB_PORT>"
  accessKey: "<ACCESS_KEY>"
  secretKey: "<SECRET_KEY>"
```

4.  Create secret using following command
    ```
    oc create -f itxa-secrets.yaml
    ```

#### Once secret is created using above steps, make following changes in `values.yaml` file in order to install new database.

```yaml
global:
  appSecret: "<SECRET_NAME_CREATED_USING_ABOVE_STEPS>"
  database:
    dbvendor: <DBTYPE>

  install:
    itxaUI:
      enabled: false
    itxadbinit:
      enabled: false

itxadatasetup:
  dbType: "oracle"
  deployPacks:
    edi: false
    fsp: false
    hc: false
  tenantId: ""
  ignoreVersionWarning: true
  loadFactoryData: "install"
```

Then run helm install command to install database.

```
 helm install my-release [chartpath] --timeout 3600
```

### Import Maps into database

### DB2:

#### Steps to enable SSL on DB2 server:


## Upgrading the Chart

You would want to upgrade your deployment when you have a new docker image for application server or a change in configuration, for e.g. new application servers to be deployed/started.

1. Ensure that the chart is downloaded locally by following the instructions given [here.](https://www.ibm.com/support/knowledgecenter/SS4QMC_10.0.0/installation/ITXARHOC_downloadHelmchart.html)

2. Ensure that the `itxadatasetup.loadFactoryData` parameter is set to `donotinstall` or blank. Run the following command to upgrade your deployments.

```
helm upgrade my-release -f values.yaml [chartpath] --timeout 3600 --tls
```

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment run the command:

```
 helm delete my-release  --tls
```

Note: If you need to clean the installation you may also consider deleting the secrets and peristent volume created as part of prerequisites.