#!/usr/bin/env bash
set -e
set -o pipefail

# Validate required environment variables
if [[ -z "$OCI_REGISTRY_URL" ]]; then
    echo "OCI_REGISTRY_URL environment variable is not set"
    exit 1
fi
if [[ -z "$OCI_REGISTRY_NAMESPACE" ]]; then
    echo "OCI_REGISTRY_NAMESPACE environment variable is not set"
    exit 1
fi

if [[ ! -z $OCI_REGISTRY_USER_NAME ]] && [[ ! -z $OCI_REGISTRY_USER_PASSWORD ]]; then
    echo "Logging into OCI registry"
    echo $OCI_REGISTRY_USER_PASSWORD | helm registry login $OCI_REGISTRY_URL --username $OCI_REGISTRY_USER_NAME --password-stdin
fi

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHARTS_DIR="$(realpath "$DIR/../charts")"

echo "Releasing local charts from $CHARTS_DIR to oci://${OCI_REGISTRY_URL}/${OCI_REGISTRY_NAMESPACE}/"

for CHART_DIR in $(ls $CHARTS_DIR); do
    echo "Releasing Helm chart: $CHART_DIR"
    pushd "$CHARTS_DIR/$CHART_DIR" > /dev/null
    helm dep update
    helm dep build
    CHART_PKG_PATH="$(helm package . | cut -d ':' -f2 | awk '{print $1}')"
    helm push $CHART_PKG_PATH "oci://${OCI_REGISTRY_URL}/${OCI_REGISTRY_NAMESPACE}"
done
