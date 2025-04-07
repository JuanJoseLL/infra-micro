#!/bin/bash
set -e

RESOURCE_GROUP=$(terraform output -raw resource_group_name)
AKS_CLUSTER_NAME=$(terraform output -raw aks_cluster_name)
ACR_SERVER=$(terraform output -raw acr_login_server)

az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME --overwrite-existing

kubectl apply -f ./kubernetes/namespace.yaml

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.replicaCount=2

kubectl apply -f ./kubernetes/

