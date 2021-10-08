#!/usr/bin/env bash
source helper.sh

minikube start -p cluster-1 --cpus=4
# minikube start -p cluster-1 --vm=true --driver=hyperkit --cpus=4

# In offline environments you should uncomment the lines below
#
# eval $(minikube docker-env -p cluster-1)

echo ".: setting up boundary in kubectl cluster and context"
kubectl config set-cluster boundary-cluster-1 --server=http://boundary-set --certificate-authority=$HOME/.minikube/ca.crt
kubectl config set-context boundary-cluster-1 --cluster=boundary-cluster-1 --user=cluster-1 --namespace=default
