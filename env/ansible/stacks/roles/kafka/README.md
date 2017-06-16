This role instantiates the Kafka VM or kafka cluster

In order to run get automatically provisioned kafka cluster
create the following play-book:

---
- name: PROVISION KAFKA VM OR CLUSTER PLAYBOOK
  hosts: all

  roles:
    - java
    - Zookeeper
    - kafka


and execute the folloving command with modifications:
# Instantiate a kafka_cluster
ansible-playbook -i inventory/az_eastus2_dev-nethawk-kafka \
 -l kafka_cluster provision_kafka.yml \
 -e zookeeper_repo_user=changeForAppropriateValueHere \
 -e zookeeper_repo_pass=changeForAppropriateValueHere \
 -e kafka_repo_user=changeForAppropriateValueHere \
 -e kafka_repo_pass=changeForAppropriateValueHere \
 -e java_repo_user=changeForAppropriateValueHere \
 -e java_repo_pass=changeForAppropriateValueHere \
 -e from_scratch=True \
 -e zookeeper_clustered=True \
 -e kafka_clustered=True \
 -e add_user_env_vars=True \
 -k -K 

# Start a kafka_cluster
ansible-playbook -i inventory/az_eastus2_dev-nethawk-kafka \
 -l kafka_cluster provision_kafka.yml \
 -t start_zookeeper,start_kafka

# Stop a kafka_cluster

To stop kafka you  have two options:

1) to stop just kafka:

ansible-playbook -i inventory/az_eastus2_dev-nethawk-kafka -l kafka_cluster provision_kafka.yml  -t stop_kafka

2) to stop kafka and zookeeper altogather in one shot:
ansible-playbook -i inventory/az_eastus2_dev-nethawk-kafka -l kafka_cluster provision_kafka.yml  -t stop_kafka && ansible-playbook -i inventory/az_eastus2_dev-nethawk-kafka -l kafka_cluster provision_kafka.yml  -t stop_zookeeper

You can not use just two tags stop_zookeeper,stop_kafka in one playbook-run because it will stop zookeeper first and then kafka will not be able to cleanly shutdown. I recommend to use two separate commands for stopping kafka cluster as in the second variant.
