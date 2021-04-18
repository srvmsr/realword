#!/usr/bin/env bash

#Change the inventory file if not on localhost
apt install ansible

ansible-playbook -i ansible/inventory ansible/playbook.yml

