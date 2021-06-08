# run-tyk-k8s

A convenient shell script to run the Tyk API Gateway on Kubernetes with ease without having to run a bajillion commands. This will install both the Tyk-CE (headless) gateway and the Tyk-Operator (a Kubernetes operator to configure Tyk-CE through CRDs).

## Prerequisites

- A Kubernetes cluster running with `kubectl` already configured to control it
- Helm
- Export a unique API key for Tyk to use as the admin API key - `export TYK_API_KEY=(ANY_SECURE_API_KEY)`

To run `up` or `up-operator` commands you must first run `./launch.sh initialize` for launch to get all charts required. Then run `./launch.sh up-ns` to create the Kubernetes Tyk namespaces needed.

## Commands

## `up-ns`

Run `./launch.sh up-ns` to create the namespaces required in Kubernetes

## `down-ns`

Run `./launch.sh down-ns` to destroy the namespaces created in Kubernetes

## `up`

Run `./launch.sh up` to install tyk-helm-chart and all it's deps

## `down`

Run `./launch.sh down` to uninstall tyk-helm-chart chart and all it's deps

## `up-operator`

Run `./launch.sh up-operator` to install tyk-operator chart and all it's deps

## `down-operator`

Run `./launch.sh up-operator` to uninstall tyk-operator chart and all it's deps

## `pf-control`

Run `./launch.sh pf-control` to port forward the Tyk control API port (admin API) to your local host port of 9696

## `pf-gateway`

Run `./launch.sh pf-gateway` to port forward the Tyk gateway port to your local host port of 8080 (the main traffic port)

## `pf`

Run `./launch.sh pf` to port forward both the control API port and the gateway port to 9696 and 8080 respectively. 