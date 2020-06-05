#!/usr/bin/env bash

CLUSTER_TYPE="$1"
NAMESPACE="$2"
INGRESS_SUBDOMAIN="$3"
NAME="$4"
STORAGE_CLASS_NAME="$5"
TLS_SECRET_NAME="$6"

if [[ -z "${NAME}" ]]; then
  NAME=eclipse-che
fi

if [[ -z "${TLS_SECRET_NAME}" ]]; then
  TLS_SECRET_NAME=$(echo "${INGRESS_SUBDOMAIN}" | sed -E "s/([^.]+).*/\1/g")
fi

if [[ -z "${TMP_DIR}" ]]; then
  TMP_DIR=".tmp"
fi
mkdir -p "${TMP_DIR}"

if [[ -z "${PVC_STRATEGY}" ]]; then
  PVC_STRATEGY="common"
fi

if [[ -z "${PVC_CLAIM_SIZE}" ]]; then
  PVC_CLAIM_SIZE="1Gi"
fi

if [[ "${CLUSTER_TYPE}" == "kubernetes" ]]; then
  HOST="${NAME}-${NAMESPACE}.${INGRESS_SUBDOMAIN}"
fi

YAML_FILE=${TMP_DIR}/che-instance-${NAME}.yaml

if [[ "${CLUSTER_TYPE}" == "kubernetes" ]]; then
  OPENSHIFT_OAUTH="false"
else
  OPENSHIFT_OAUTH="true"
fi

cat <<EOL > ${YAML_FILE}
apiVersion: org.eclipse.che/v1
kind: CheCluster
metadata:
  name: ${NAME}
spec:
  server:
    cheImageTag: ''
    devfileRegistryImage: ''
    pluginRegistryImage: ''
    tlsSupport: true
    selfSignedCert: false
  database:
    externalDb: false
    chePostgresHostName: ''
    chePostgresPort: ''
    chePostgresUser: ''
    chePostgresPassword: ''
    chePostgresDb: ''
  auth:
    openShiftoAuth: ${OPENSHIFT_OAUTH}
    identityProviderImage: ''
    externalIdentityProvider: false
    identityProviderURL: ''
    identityProviderRealm: ''
    identityProviderClientId: ''
  storage:
    postgresPVCStorageClassName: ${STORAGE_CLASS_NAME}
    workspacePVCStorageClassName: ${STORAGE_CLASS_NAME}
    pvcStrategy: ${PVC_STRATEGY}
    pvcClaimSize: ${PVC_CLAIM_SIZE}
    preCreateSubPaths: true
EOL

kubectl apply -f ${YAML_FILE} -n "${NAMESPACE}"

sleep 2

kubectl rollout status deployment/${NAME} -n "${NAMESPACE}"
