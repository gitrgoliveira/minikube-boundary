#!/usr/bin/env bash
source helper.sh

minikube start -p cluster-1 --cpus=4

echo ".: setting up boundary in kubectl cluster and context"
kubectl config set-cluster boundary-cluster-1 --server=http://boundary-set --certificate-authority=$HOME/.minikube/ca.crt
kubectl config set-context boundary-cluster-1 --cluster=boundary-cluster-1 --user=cluster-1 --namespace=default
