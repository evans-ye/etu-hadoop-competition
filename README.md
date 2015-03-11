# ETU Hadoop Competition 2014 Preliminary Winner Scripts

WARNING!!! This project CAN NOT be used w/o modification!

This project is highly customized in accordance to the rule and environment provided by contest host.

Preparation
==============================
* Install Virtualbox
  https://www.virtualbox.org/wiki/Downloads

* Install Vagrant
  http://www.vagrantup.com/downloads.html

* Update aws access key and secret key in Vagrantfile
```
aws.access_key_id = "ACCESS_KEY_HERE"
aws.secret_access_key = "SECRET_KEY_HERE"
```

* Download the private key for ssh login and put the file name in Vagrantfile
```
override.ssh.private_key_path = "PRIVATE_KEY.pem_HERE"
```

Usage
==============================
* Provision a ec2 instance for hadoop deployment
```
$ ./startup.sh
```
* Manually run the provision script
```
$ ./provision.sh
```
