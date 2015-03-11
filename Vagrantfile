Vagrant.configure("2") do |config|
  config.vm.box = "dummy"
  config.vm.box_url = "https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box"

  # manage /etc/hosts by hostmanager plugin(https://github.com/smdahlen/vagrant-hostmanager)
  #config.hostmanager.enabled = true

  config.vm.provider :aws do |aws, override|
    aws.tags = {
      'Name' => 'hadoop-aws',
    }
    aws.access_key_id = "YOUR_ACCESS_KEY"
    aws.secret_access_key = "YOUR_SECRET_KEY"
    aws.keypair_name = "vagrant-aws"
    aws.region = "ap-southeast-1"
    aws.security_groups = ["HADOOP"]

    # https://aws.amazon.com/marketplace/ordering/ref=dtl_psb_continue?ie=UTF8&productId=adc4348e-1dc3-41df-b833-e86ba57a33d6&region=ap-southeast-1
    aws.ami = "ami-21682673"

    aws.instance_type = "m3.medium"
    aws.availability_zone = "ap-southeast-1b"

    override.ssh.username = "root"
    # download the private key from aws web console and named it vagrant-awws.pem
    override.ssh.private_key_path = "vagrant-aws.pem"
  end 

  config.vm.define :aws1

end
