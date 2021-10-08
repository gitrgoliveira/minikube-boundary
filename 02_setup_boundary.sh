#! /bin/bash
source helper.sh
# set -eu
# set -o pipefail

c1_kctx
setup-boundary
export BOUNDARY_CLI_FORMAT=json

if [ ! -s boundary_auth_methods.json ]; then
    boundary auth-methods list -format json | jq > boundary_auth_methods.json
fi

PROJECT_ID=$(boundary scopes list -recursive -format json | jq  -r '.items[] | select(.name | contains("Generated project scope")) | .id')

if [ ! -s boundary_login.json ]; then
echo ".:boundary:. Getting login information"
kubectl -n boundary logs deployment/boundary  -c boundary-init | jq  > boundary_login.json
fi

echo ".:boundary:. Got Project ID: $PROJECT_ID"

if [ ! -s boundary_host_catalogs.json ]; then
boundary host-catalogs create static -scope-id=$PROJECT_ID -name=k8s-services \
    -description="k8s services" > boundary_host_catalogs.json
fi

KUBE_API=$(kubectl get svc kubernetes -o json | jq -r  .spec.clusterIP)
HOST_CATALOG_ID=$(cat boundary_host_catalogs.json | jq -r .item.id)

if [ ! -s boundary_host.json ]; then
boundary hosts create static -name=kube-api -description="k8s clusterIP" \
    -address=$KUBE_API -host-catalog-id=$HOST_CATALOG_ID > boundary_host.json
fi

if [ ! -s boundary_host_sets.json ]; then
boundary host-sets create static -name="kube-api" \
    -description="k8s clusterIP" -host-catalog-id=$HOST_CATALOG_ID > boundary_host_sets.json
fi

HOST_ID=$(cat boundary_host.json | jq -r .item.id)
HOST_SET_ID=$(cat boundary_host_sets.json | jq -r .item.id)

boundary host-sets add-hosts -id=$HOST_SET_ID -host=$HOST_ID || true

if [ ! -s boundary_target.json ]; then
boundary targets create tcp -name="k8s-api" -description="k8s api" \
    -worker-filter='"cluster-1" in tags/cluster' \
    -default-port=443 -scope-id=$PROJECT_ID -session-connection-limit="-1" > boundary_target.json
fi

TARGET_ID=$(cat boundary_target.json | jq -r .item.id)

boundary targets add-host-sets -id=$TARGET_ID -host-set=$HOST_SET_ID

# --- demo ---
# kubectl config use-context boundary-cluster-1

# export BOUNDARY_ADDR=http://127.0.0.1:9200/
# export PROJECT_ID=$(boundary scopes list -recursive -format json | jq  -r '.items[] | select(.name | contains("Generated project scope")) | .id')

# AUTH_METHOD_ID=$(cat boundary_login.json | jq -r .auth_method.auth_method_id) &&
# PASSWORD=$(cat boundary_login.json | jq -r .auth_method.password) && \
# boundary authenticate password \
#          -login-name=admin \
#          -password $PASSWORD \
#          -auth-method-id=$AUTH_METHOD_ID

# unset BOUNDARY_RECOVERY_CONFIG

# boundary connect kube -target-name=k8s-api  -target-scope-id $PROJECT_ID -- get pods