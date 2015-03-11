#!/bin/bash

USER=${1:-team29}
PRIVATE_KEY=${2:-vagrant-aws.pem}

vagrant up --provider=aws
IP=`vagrant ssh-config aws1 |grep HostName |cut -d' ' -f 4`

# create default user to simulate the environment
ssh -i $PRIVATE_KEY -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $IP "useradd $USER; echo '$USER ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers; cp -r .ssh /home/$USER/; chown -R $USER:$USER /home/$USER/;"

# drop the provision.sh script which will be placed on s3 bucket and use wget to download
scp -i $PRIVATE_KEY -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no provision.sh $USER@$IP:~

# ssh login to VM
ssh -i $PRIVATE_KEY -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $USER@$IP
