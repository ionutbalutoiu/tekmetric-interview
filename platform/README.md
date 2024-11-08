# Platform Engineering Interview Home Project

This directory contains the Platform Engineering Interview home project for Tekmetric.

Table of Contents:

- [Platform Engineering Interview Home Project](#platform-engineering-interview-home-project)
  - [Overview](#overview)
  - [Requirements](#requirements)
  - [Application Deployment](#application-deployment)
    - [Automated Deployment via GitHub Actions](#automated-deployment-via-github-actions)
    - [Manual Deployment from Local Machine](#manual-deployment-from-local-machine)
      - [Staging Environment](#staging-environment)
      - [Production Environment](#production-environment)

## Overview

The `platform` directory contains the following sub-directories:

- `charts` - Production-ready Helm charts for deploying the applications.
- `helm_values` - Helm values files for deploying the applications, including environment-specific configurations.
- `scripts` - Scripts to assist with building and deploying the applications.

## Requirements

- [Helm v3](https://helm.sh/docs/intro/install) tool installed.
- [Kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl) tool installed.
- A Kubernetes cluster deployed locally or on a cloud provider. This is required for Helm app deployments. There are a few **important notes** here, the current `helm_values` files assume that:
  - [Traefik Ingress Controller](https://doc.traefik.io/traefik/providers/kubernetes-ingress/) is installed on the cluster. However, you can modify the ingress annotations in the `helm_values` files to use a different ingress controller.
  - Prometheus is installed on the cluster, and the [ServiceMonitor](https://github.com/prometheus-operator/prometheus-operator/blob/v0.78.1/Documentation/user-guides/getting-started.md#using-servicemonitors) CRD is available to scrape metrics from the applications.
  - A separate pool of workers (labeled with `node-pool=k3s-workers` and tainted with `spring-boot-apps:NoSchedule`) is available to run the applications. This ensures that the Java Spring Boot applications are scheduled on a dedicated node pool of workers.

## Application Deployment

Currently, we have `platform/charts/tekmetric-app` as a base Helm chart for deploying the Tekmetric applications. The chart is designed to be reusable and can be used to deploy multiple instances of the application with different configurations:

```shell
platform/charts/tekmetric-app
├── Chart.yaml
├── templates
│   ├── _helpers.tpl
│   ├── configmap.yaml
│   ├── deployment.yaml
│   ├── hpa.yaml
│   ├── ingress.yaml
│   ├── pdb.yaml
│   ├── secret.yaml
│   ├── service-monitor.yaml
│   ├── service.yaml
│   └── serviceaccount.yaml
└── values.yaml
```

In addition to the `platform/charts/tekmetric-app` Helm chart, the `platform/helm_values` directory contains environment-specific configurations (as Helm values files) for deploying the applications via Helm. The directory structure is as follows:

```shell
platform/helm_values
└── backend
    ├── production
    │   ├── secrets.yaml
    │   └── values.yaml
    └── staging
        ├── secrets.yaml
        └── values.yaml
    ...
```

If another application needs to be deployed, you can add environment-specific configurations in the `platform/helm_values` directory, similar to the `backend` application.

### Automated Deployment via GitHub Actions

This repository contains GitHub Actions workflows that automatically build and deploy the applications to the Kubernetes clusters as follows:

- `.github/workflows/deploy-staging.yaml` - On every push to the `master` branch:
  - A new Docker image is built and pushed to the GitHub Container Registry (using the commit ID as the image tag).
  - The application is deployed to the staging environment.
- `.github/workflows/deploy-production.yaml` - On every release created in the GitHub repository:
  - A new Docker image is built and pushed to the GitHub Container Registry (using the release tag as the image tag).
  - The application is deployed to the production environment.

The GitHub Actions workflows use the following secrets:

- `STAGING_KUBECONFIG_BASE64` - Base64 encoded kubeconfig file for the staging cluster (manually added as a repository secret).
- `PRODUCTION_KUBECONFIG_BASE64` - Base64 encoded kubeconfig file for the production cluster (manually added as a repository secret).
- `GITHUB_TOKEN` - Token used by GitHub Actions to authenticate with the GitHub Container Registry (`ghcr.io`) for pushing Docker images and publishing Helm charts.

### Manual Deployment from Local Machine

To deploy the applications manually from your local machine, you can use the `platform/scripts/deploy-helm-release.sh` script. The script is designed to run `helm install / upgrade` using a local Helm chart (or OCI registry Helm chart) and environment-specific Helm values file.

#### Staging Environment

To deploy the `backend` application to the staging environment, run the following command:

```shell
export KUBECONFIG="$HOME/.kube/staging_kubeconfig.yaml"

export HELM_NAMESPACE="backend-staging"
export HELM_RELEASE_NAME="backend-staging"
export LOCAL_CHART_PATH="./platform/charts/tekmetric-app"
export HELM_OPTS="\
  --atomic \
  --wait \
  -f ./platform/helm_values/backend/staging/values.yaml \
  -f ./platform/helm_values/backend/staging/secrets.yaml \
"

./platform/scripts/deploy-helm-release.sh
```

The script will do the following:

- Use the `KUBECONFIG` for the staging cluster.
- Use the local `platform/charts/tekmetric-app` Helm chart.
- Deploy the `backend` application to the `backend-staging` namespace, using the `backend-staging` release name, and using the Helm values files:
  - `platform/helm_values/backend/staging/values.yaml`
  - `platform/helm_values/backend/staging/secrets.yaml`

#### Production Environment

To deploy the `backend` application to the production environment, run the following command:

```shell
export KUBECONFIG="$HOME/.kube/production_kubeconfig.yaml"

export HELM_NAMESPACE="backend-production"
export HELM_RELEASE_NAME="backend-production"
export HELM_OCI_CHART="oci://ghcr.io/ionutbalutoiu/chart-tekmetric-app"
export HELM_OCI_CHART_VERSION="0.2.0"
export HELM_OPTS="\
  --atomic \
  --wait \
  -f ./platform/helm_values/backend/production/values.yaml \
  -f ./platform/helm_values/backend/production/secrets.yaml \
"

./platform/scripts/deploy-helm-release.sh
```

The above script will do the following:

- Use the `KUBECONFIG` for the production cluster.
- Use the OCI registry `ghcr.io` Helm chart `chart-tekmetric-app` version `0.2.0`.
- Deploy the `backend` application to the `backend-production` namespace, using the `backend-production` release name, and using the Helm values files:
  - `platform/helm_values/backend/production/values.yaml`
  - `platform/helm_values/backend/production/secrets.yaml`
