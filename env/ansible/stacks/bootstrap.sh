#!/usr/bin/env bash
export ANSIBLE_FORCE_COLOR=true
export PYTHONUNBUFFERED=true
export ANSIBLE_HOST_KEY_CHECKING=False
ansible-playbook azure_create_vm.yml \
-e "azure_credentials_profile=newgistics \
azure_subscription_id=c122ac67-xxxx-xxxx-xxxx-f42cac2355f7 \
azure_client_id=xxxxxxxx-c1f1-4c1a-xxxx-b065f13876e1 \
azure_secret=SuperSecretString \
azure_tenant=xxxxxxxx-xxxxx-xxxx-xxxx-c88d1723c382" && \
ansible-playbook -i $(ls -1d /tmp/*_Azure_VM| tail -n1) azure_provision_vm.yml && \
rm -rf $(ls -1d /tmp/*_Azure_VM| tail -n1) 
