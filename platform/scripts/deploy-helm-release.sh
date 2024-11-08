#!/usr/bin/env bash
set -e
set -o pipefail

# Validate required environment variables
if [[ -z "${HELM_NAMESPACE}" ]]; then
    echo "ERROR: HELM_NAMESPACE environment variable is required"
    exit 1
fi
if [[ -z "${HELM_RELEASE_NAME}" ]]; then
    echo "ERROR: HELM_RELEASE_NAME environment variable is required"
    exit 1
fi

# Add various options to the HELM_OPTS
HELM_OPTS=${HELM_OPTS:-""}
HELM_OPTS="${HELM_OPTS} --namespace=${HELM_NAMESPACE} --create-namespace"

# Determine the chart to deploy (either from local or OCI)
if [[ ! -z ${LOCAL_CHART_PATH} ]]; then
    pushd ${LOCAL_CHART_PATH} >/dev/null
    helm dep update
    helm dep build
    HELM_CHART="$(helm package . | cut -d ':' -f2 | awk '{print $1}')"
    popd >/dev/null
elif [[ ! -z ${HELM_OCI_CHART} ]]; then
    HELM_CHART=${HELM_OCI_CHART}
    if [[ -z ${HELM_OCI_CHART_VERSION} ]]; then
        echo "ERROR: OCI chart (HELM_OCI_CHART env var) is specified, but chart version (HELM_OCI_CHART_VERSION env var) is not specified"
        exit 1
    fi
    HELM_OPTS="${HELM_OPTS} --version ${HELM_OCI_CHART_VERSION}"
else
    echo "ERROR: No local chart path or OCI chart specified"
    exit 1
fi

# Determine the Helm operation (install or upgrade)
HELM_OP="install"
if helm list -n ${HELM_NAMESPACE} | grep -q "^${HELM_RELEASE_NAME}"; then
    # If the release already exists, upgrade it
    HELM_OP="upgrade"
fi

# Deploy Helm release
echo "Deploying Helm release ${HELM_RELEASE_NAME} in namespace ${HELM_NAMESPACE}"
helm $HELM_OP $HELM_OPTS ${HELM_RELEASE_NAME} $HELM_CHART
