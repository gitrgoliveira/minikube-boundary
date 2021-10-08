#! /bin/bash
source helper.sh
# set -eu
# set -o pipefail

c1_kctx

vault server -dev -dev-root-token-id=root -dev-plugin-dir=./vault-plugins -combine-logs 2>&1 > ./vault.log &

kubectl apply -f manifests/vault/
secret_name=$(kubectl get serviceaccount/vault-dynamic-creds-backend -o jsonpath='{.secrets[0].name}')
k8_cacert=$(kubectl get secret/${secret_name} -o jsonpath='{.data.ca\.crt}'|base64 --decode)
sa_token=$(kubectl get secret/${secret_name} -o jsonpath='{.data.token}'|base64 -d)
server=$(kubectl config view --output json | jq -r '.clusters[] | select(.name=="cluster-1") | .cluster.server')

export VAULT_ADDR="http://127.0.0.1:8200" \
&& vault login root \
&& vault secrets enable -path=k8s vault-k8s-secret-engine-darwin \
&& vault secrets list \
&& vault write k8s/config viewer_role="reader_role" admin_role="admin_role" editor_role="editor_role" \
jwt="${sa_token}" \
ca_cert="${k8_cacert}" \
host="${server}" \
max_ttl=1h \
ttl=10m
