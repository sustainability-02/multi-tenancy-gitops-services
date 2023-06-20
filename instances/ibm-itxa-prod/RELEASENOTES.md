# What's new in IBM Transformation Extender Advanced Software Enterprise Edition v10 Helm Charts

- IBM Transformation Extender Advanced Software can be deployed in the form of docker images with DB2/Oracle/MSSQL database.
- Support for affinity configurations added.

# Breaking Changes

- Rolling upgrade from previous chart version `1.0.0` to this release is not supported, due to migration to new standard chart labels provided by kubernetes and helm.

# Documentation

- ITXA - IBM Transformation Extender Advanced

# Fixes

N/A

# Prerequisites

1. Kubernetes version >= 1.17
2. DB2/Oracle/MSSQL database server is installed. The database should be accessible from inside the cluster.
3. Ensure that the timezone considerations for the deployment are made. Refer section "Timezone considerations" in readme for details.
4. The docker images for IBM Transformation Extender Advanced Software Enterprise are loaded to an appropriate docker registry. IBM Transformation Extender Advanced Software can be loaded from IBM Entitled Registry.
5. Ensure that the docker registry used is configured in "Image Policies" in Manage -> Resource Security -> Image Policies
6. Ensure that docker image can be pulled on all of Kubernetes worker nodes.
7. Create one persistent volumes with access mode as 'Read write many' with minimum 12GB space one for ITXA.

# Version History

| Chart | Date      | Kubernetes | Image(s) Supported                                                        | Breaking Changes  | Details                                                                                           |
| ----- | --------- | ---------- | ------------------------------------------------------------------------- | ----------------- | ------------------------------------------------------------------------------------------------- |
| 1.0.0 | Sep, 2021 | >=1.17     | itxa-init-db:10.0.1.7_APR_04_04_6 and itxa-ui-server:10.0.1.7_APR_04_04_6 | Initial on Helm 3 | This is the version for IBM Transformation Extender Advanced Software Software v10.0.1 Helm Chart |
