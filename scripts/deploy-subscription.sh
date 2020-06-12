#!/usr/bin/env bash

CLUSTER_TYPE="$1"
OPERATOR_NAMESPACE="$2"
OLM_NAMESPACE="$3"

if [[ -z "${TMP_DIR}" ]]; then
  TMP_DIR=".tmp"
fi
mkdir -p "${TMP_DIR}"

if [[ "${CLUSTER_TYPE}" == "ocp4" ]]; then
  SOURCE="community-operators"
else
  SOURCE="operatorhubio-catalog"
fi

if [[ -z "${OLM_NAMESPACE}" ]]; then
  if [[ "${CLUSTER_TYPE}" == "ocp4" ]]; then
    OLM_NAMESPACE="openshift-marketplace"
  else
    OLM_NAMESPACE="olm"
  fi
fi

YAML_FILE=${TMP_DIR}/eclipse-che-subscription.yaml

cat <<EOL > ${YAML_FILE}
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: eclipse-che
spec:
  channel: stable
  installPlanApproval: Automatic
  name: eclipse-che
  source: $SOURCE
  sourceNamespace: $OLM_NAMESPACE
EOL

kubectl apply -f ${YAML_FILE} -n "${OPERATOR_NAMESPACE}"

count=0
RETRIES=10
until kubectl get crd checlusters.org.eclipse.che 1> /dev/null 2> /dev/null || [[ "${count}" -eq "${RETRIES}" ]]; do
  echo "EclipseChe CRD not installed, will retry after 15 seconds"
  sleep 15
  count=$((count + 1))
done

if [[ "${count}" -eq "${RETRIES}" ]]; then
  echo "Timed out waiting for EclipseChe CRD to install"
  exit 1
fi
