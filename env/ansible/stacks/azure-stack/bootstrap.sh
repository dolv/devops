#!/usr/bin/env bash
export ANSIBLE_FORCE_COLOR=true
export PYTHONUNBUFFERED=true
export ANSIBLE_HOST_KEY_CHECKING=False
ansible-playbook azure_create_vm.yml -t vm && \
ansible-playbook -i $(ls -1d /tmp/*_Azure_VM| tail -n1) azure_provision_vm.yml && \
rm -rf $(ls -1d /tmp/*_Azure_VM| tail -n1) 
