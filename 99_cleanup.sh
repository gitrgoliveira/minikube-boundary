
kubectl config use-context cluster-1
kubectl delete -f ./manifests/boundary
kubectl delete -f ./manifests/postgres

killall minikube

rm *.json