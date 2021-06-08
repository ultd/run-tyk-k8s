#!/bin/bash

set -eo pipefail

if [ $1 == "initialize" ]
then
    mkdir charts
    git clone https://github.com/TykTechnologies/tyk-helm-chart ./charts/tyk-helm-chart
    git clone https://github.com/TykTechnologies/tyk-operator ./charts/tyk-operator
    echo "Initialized launch.sh.. run your commands now :)"
    exit 0
fi

if [[ -z "${TYK_API_KEY}" ]]
then
    echo "Env variable 'TYK_API_KEY' must be set when using launcher"
    exit 1
fi

if [ $1 == "up" ]
then
    echo "Making sure bitnami repo added to helm.."
    helm repo add bitnami https://charts.bitnami.com/bitnami
    echo "Updating helm repos.."
    helm repo update
    echo "Installing helm chart bitnami/redis.."
    helm install tyk-redis bitnami/redis -n tyk
    export REDIS_PASSWORD=$(kubectl get secret --namespace tyk tyk-redis -o jsonpath="{.data.redis-password}" | base64 --decode)
    echo "Got redis pass: $REDIS_PASSWORD"
    helm install \
        -n tyk \
        -f values.yml \
        --set "redis.pass=$REDIS_PASSWORD" \
        --set "redis.addrs={tyk-redis-master.tyk.svc.cluster.local:6379}" \
        --set "secrets.APISecret=$TYK_API_KEY" \
        --set "gateway.control.enabled=true" \
        tyk-ce \
        ./charts/tyk-helm-chart/tyk-headless
    echo "All is good. Go for it :)"
    exit 0
elif [ $1 == "down" ]
then
    echo "Uninstalling helm chart tyk-headless (tyk-ce).."
    helm uninstall -n tyk tyk-ce
    echo "Uninstalling helm chart tyk-redis.."
    helm uninstall -n tyk tyk-redis
    unset REDIS_PASSWORD
    echo "Done tearing down the enitre infrastructure :\\"
    exit 0
elif [ $1 == "pf-control" ]
then
    echo "Port forwarding service/gateway-control-svc-tyk-headless to 127.0.0.1:9696.."
    kubectl -n tyk port-forward service/gateway-control-svc-tyk-headless 9696:9696
    exit 0
elif [ $1 == "pf-gateway" ]
then
    echo "Port forwarding service/gateway-svc-tyk-headless to 127.0.0.1:8080.."
    kubectl -n tyk port-forward service/gateway-svc-tyk-headless 8080:443
    exit 0
elif [ $1 == "pf" ]
then
    echo "Port forwarding service/gateway-svc-tyk-headless to 127.0.0.1:8080.."
    echo "Port forwarding service/gateway-control-svc-tyk-headless to 127.0.0.1:9696.."
    kubectl -n tyk port-forward service/gateway-control-svc-tyk-headless 9696:9696 \
    & kubectl -n tyk port-forward service/gateway-svc-tyk-headless 8080:443
    exit 0
elif [ $1 == "up-operator" ]
then 
    CERT_MANAGER_INSTALLED=$(kubectl get all -n cert-manager)
    if [ CERT_MANAGER_INSTALLED == "No resources found in cert-manager namespace." ]
    then
        echo "You must install (and wait to come to life) cert-manager by using './launch.sh install-cert-manager'"
        exit 1
    fi
    echo "Creating tyk-operator-conf secret in tyk-operator-system namespace.."
    kubectl create secret -n tyk-operator-system generic tyk-operator-conf \
        --from-literal "TYK_AUTH=${TYK_API_KEY}" \
        --from-literal "TYK_ORG=1" \
        --from-literal "TYK_MODE=ce" \
        --from-literal "TYK_URL=http://gateway-control-svc-tyk-headless:9696" \
        --from-literal "TYK_TLS_INSECURE_SKIP_VERIFY=true"
    echo "Set tyk-operator-conf secret: "
    kubectl get secret/tyk-operator-conf -n tyk-operator-system -o json | jq '.data'
    echo "Registering tyk-operator CRDs with Kubernetes.."
    kubectl apply -f ./charts/tyk-operator/helm/crds
    echo "Installing tyk-operator in tyk-operator-system namespace.."
    helm install tyk-operator ./charts/tyk-operator/helm -n tyk-operator-system
    echo "Successfully installed the tyk-operator :_)"
    exit 0
elif [ $1 == "down-operator" ]
then
    echo "Uninstall tyk-operator Helm chart.."
    helm delete -n tyk-operator-system tyk-operator
    echo "Unregistering tyk-operator CRDs from Kubernetes.."
    kubectl delete -f ./charts/tyk-operator/helm/crds
    echo "Deleting tyk-operator-conf secret from tyk-operator-system namespace.."
    kubectl delete secret -n tyk-operator-system tyk-operator-conf
    echo "Successfully downed all tyk-operator resources :/"
    exit 0
elif [ $1 == "up-ns" ]
then 
    echo "Creating tyk-operator-system namespace.."
    kubectl create namespace tyk-operator-system
    echo "Creating tyk namespace.."
    kubectl create namespace tyk
    echo "Successfully created all namespaces :)"
    exit 0
elif [ $1 == "down-ns" ]
then 
    echo "Deleting tyk-operator-system namespace.."
    kubectl delete namespace tyk-operator-system
    echo "v tyk namespace.."
    kubectl delete namespace tyk
    echo "Successfully deleted all namespaces :/"
    exit 0
elif [ $1 == "install-cert-manager" ]
then 
    echo "Installing cert manager.."
    kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.0.3/cert-manager.yaml
    echo "Successfully installed cert-manager. Use './launch.sh status-cert-manager' to see it's status :)"
    exit 0
elif [ $1 == "delete-cert-manager" ]
then
    echo "Deleting cert manager.."
    kubectl delete -f https://github.com/jetstack/cert-manager/releases/download/v1.0.3/cert-manager.yaml
    echo "Successfully delete cert-manager"
    exit 0
elif [ $1 == "status-cert-manager" ]
then 
    echo "Status cert manager:"
    kubectl get all -n cert-manager
    exit 0
else 
    echo "Error: Need valid first argument: up, down, pf, pf-gateway or pf-control"
    exit 1
fi
