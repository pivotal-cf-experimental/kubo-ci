#!/bin/bash

set -exu -o pipefail

login_gcp() {
  if bosh int "${ENV_FILE}" --path='/gcp_service_account' &> /dev/null; then
    bosh int "${ENV_FILE}" --path='/gcp_service_account' > gcp_service_account.json
  elif [[ -n "${GCP_SERVICE_ACCOUNT}" ]]; then
    set +x
    echo "${GCP_SERVICE_ACCOUNT}" > gcp_service_account.json
    set -x
  fi
  gcloud auth activate-service-account --key-file=gcp_service_account.json
  gcloud config set project "$(bosh int - --path=/project_id < gcp_service_account.json)"
  gcloud config set compute/zone "$(bosh int "${ENV_FILE}" --path='/zone')"
}

delete_gcloud_vms() {
  subnetwork=$(bosh int "${ENV_FILE}" --path='/subnetwork')
  subnetLink=$(gcloud compute networks subnets list --filter name="$subnetwork" --format=json | bosh int - --path=/0/selfLink)
  vms=$(gcloud  compute instances list --uri --filter="networkInterfaces.subnetwork=$subnetLink")

  IFS=$'\n'

  for vm in $vms; do
    gcloud compute instances delete "$vm" --delete-disks=all --quiet
  done

  unset IFS
}

delete_firewall_rules() {
  local env_name=$(bosh int ${ENV_FILE} --path='/director_name')
  local fw_rules=$(gcloud compute firewall-rules list --filter="targetTags:(${env_name}-ci-service-worker)" --format='value(NAME)')
  if [[ -n $fw_rules ]]; then
    gcloud compute firewall-rules delete --quiet $fw_rules
  fi
}

login_gcp
delete_gcloud_vms
delete_firewall_rules
