
#! /bin/bash
source helper.sh
# set -eu
# set -o pipefail

c1_kctx
export VAULT_ADDR="http://$HOST_IP:8200"
vault policy write boundary-controller - <<EOF
path "auth/token/lookup-self" {
  capabilities = ["read"]
}

path "auth/token/renew-self" {
  capabilities = ["update"]
}

path "auth/token/revoke-self" {
  capabilities = ["update"]
}

path "sys/leases/renew" {
  capabilities = ["update"]
}

path "sys/leases/revoke" {
  capabilities = ["update"]
}

path "sys/capabilities-self" {
  capabilities = ["update"]
}
EOF

vault policy write k8s-api - <<EOF
path "k8s/service_account/postgres/viewer" {
  capabilities = ["read"]
}
EOF

vault token create \
  -field=token \
  -no-default-policy=true \
  -policy="boundary-controller" \
  -policy="k8s-api" \
  -orphan=true \
  -period=20m \
  -renewable=true > boundary.token


setup-boundary
export BOUNDARY_CLI_FORMAT=json

PROJECT_ID=$(boundary scopes list -recursive -format json | jq  -r '.items[] | select(.name | contains("Generated project scope")) | .id')

if [ ! -s boundary_credential_store.json ]; then
boundary credential-stores create vault -scope-id $PROJECT_ID \
  -vault-address "http://$HOST_IP:8200" \
  -vault-token $(cat boundary.token) > boundary_credential_store.json
fi

if [ ! -s boundary_credential_library.json ]; then
boundary credential-libraries create vault \
    -credential-store-id $(jq -r  .item.id boundary_credential_store.json) \
    -vault-path "k8s/service_account/postgres/viewer" \
    -name "postgres k8s viewer" > boundary_credential_library.json
fi

TARGET_ID=$(jq -r .item.id boundary_target.json)

boundary targets add-credential-libraries \
  -id=$TARGET_ID \
  -application-credential-library=$(jq -r .item.id boundary_credential_library.json)


