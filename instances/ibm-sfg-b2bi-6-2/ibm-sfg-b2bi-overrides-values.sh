#!/usr/bin/env bash
# Set enviroment variables
# Declaring IBM SFG PROD

# SFG_REPO=SFG_REPO \
# SFG_TAG=SFG_TAG SFG_DIGEST=SFG_DIGEST \
# DB_REPO=DB_REPO DB_TAG=DB_TAG DB_DIGEST=DB_DIGEST \
# ./ibm-sfg-b2bi-overrides-values.sh


NS="b2bi-6-2"
if [[ -z ${SFG_REPO} ]]; then
  echo "Please provide environment variable SFG_REPO"
  exit 1
fi
if [[ -z ${SFG_TAG} ]]; then
  echo "Please provide environment variable SFG_TAG"
  exit 1
fi
if [[ -z ${SFG_DIGEST} ]]; then
  echo "Please provide environment variable SFG_DIGEST"
  exit 1
fi
SFG_REPO=${SFG_REPO}
SFG_TAG=${SFG_TAG}
SFG_DIGEST=${SFG_DIGEST}
SFG_PULLSECRECT=${SFG_PULLSECRECT:-"ibm-entitlement-key"}
#APP_RESOURCES_PVC_ENABLED=${APP_RESOURCES_PVC_ENABLED:-"true"}
#APP_DOCUMENTS_PVC_ENABLED=${APP_DOCUMENTS_PVC_ENABLED:-"true"}
DATASETUP_ENABLED=${DATASETUP_ENABLED:-"true"}
#DBHOST=$(oc get svc db2-lb -n ${NS} -o jsonpath='{ .status.loadBalancer.ingress[0].ip}')
if [[ -z ${DB_REPO} ]]; then
  echo "Please provide environment variable DB_REPO"
  exit 1
fi
DB_REPO=${DB_REPO}
if [[ -z ${DB_TAG} ]]; then
  echo "Please provide environment variable DB_TAG"
  exit 1
fi
DB_TAG=${DB_TAG}
if [[ -z ${DB_DIGEST} ]]; then
  echo "Please provide environment variable DB_DIGEST"
  exit 1
fi
DB_DIGEST=${DB_DIGEST}
DBHOST=$(oc get svc db2-lb -n ${NS} -o jsonpath='{ .spec.clusterIP}')
DBPORT=$(oc get svc db2-lb -n ${NS} -o jsonpath='{ .spec.ports[0].port}')
DBDATA=${DBDATA:-"B2BIDB"}
DBCREATESCHEMA=${DBCREATESCHEMA:-"true"}
JMSHOST=$(oc get svc mq-data -n ${NS} -o jsonpath='{ .spec.clusterIP}')
JMSPORT=$(oc get svc mq-data -n ${NS} -o jsonpath='{ .spec.ports[0].port}')
JMSCONNECTIONNAMELIST="$JMSHOST($JMSPORT)"
JSMCHANNEL=${JSMCHANNEL:-"DEV.APP.SVRCONN"}
INGRESS_INTERNAL_HOST_ASI="asi-${NS}."$(oc get ingress.config.openshift.io cluster -o jsonpath='{ .spec.domain }')
INGRESS_INTERNAL_HOST_AC="ac-${NS}."$(oc get ingress.config.openshift.io cluster -o jsonpath='{ .spec.domain }')
INGRESS_INTERNAL_HOST_API="api-${NS}."$(oc get ingress.config.openshift.io cluster -o jsonpath='{ .spec.domain }')
# PURGE_IMG_REPO=${PURGE_IMG_REPO:-"cp.icr.io/cp/ibm-sfg/sfg-purge"}
# PURGE_IMG_TAG=${PURGE_IMG_TAG:-"6.1.0.0"}
# PURGE_PULLSECRET=${PURGE_PULLSECRET:-"ibm-entitlement-key"}
# RWX_STORAGECLASS=${RWX_STORAGECLASS:-"ibmc-file-gold"}

# Create Kubernetes yaml
( echo "cat <<EOF" ; cat ibm-sfg-b2bi-overrides-values.yaml_template ;) | \
SFG_REPO=${SFG_REPO} \
SFG_TAG=${SFG_TAG} \
SFG_DIGEST=${SFG_DIGEST} \
SFG_PULLSECRECT=${SFG_PULLSECRECT} \
DATASETUP_ENABLED=${DATASETUP_ENABLED} \
DB_REPO=${DB_REPO} \
DB_TAG=${DB_TAG} \
DB_DIGEST=${DB_DIGEST} \
DBHOST=${DBHOST} \
DBPORT=${DBPORT} \
DBDATA=${DBDATA} \
DBCREATESCHEMA=${DBCREATESCHEMA} \
JMSHOST=${JMSHOST} \
JMSPORT=${JMSPORT} \
JMSCONNECTIONNAMELIST=${JMSCONNECTIONNAMELIST} \
JSMCHANNEL=${JSMCHANNEL} \
INGRESS_INTERNAL_HOST_ASI=${INGRESS_INTERNAL_HOST_ASI} \
INGRESS_INTERNAL_HOST_AC=${INGRESS_INTERNAL_HOST_AC} \
INGRESS_INTERNAL_HOST_API=${INGRESS_INTERNAL_HOST_API} \
sh > values.yaml
