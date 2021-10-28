
source helper.sh
kubectl config use-context cluster-1
kubectl delete -f ./manifests/boundary
kubectl delete -f ./manifests/postgres

killall minikube
killall vault

rm *.json

removehost "worker.minikube"