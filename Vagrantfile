# -*- mode: ruby -*-
# vi: set ft=ruby :
require 'yaml'
# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"
GROUP_VARS_FILE = "./ansible-dryad/group_vars/all"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # Make sure user has copied the template file
  if not File.exists? GROUP_VARS_FILE
    abort "\n### Error building vagrant-dryad: Unable to find #{GROUP_VARS_FILE}\n\n  See the 'Getting Started' section of the README.md file\n\n"
  end
  
  begin
    group_vars = YAML::load(File.open(GROUP_VARS_FILE))
  rescue
    abort "\nError reading #{GROUP_VARS_FILE}, make sure it is valid YAML\n\n"
  end
  # Make sure user has customized the template file.
  # Use ruby exception handling to catch errors
  begin
    db_password = group_vars['dryad']['db']['password']
    if db_password.length < 1
      raise 'The dryad db password has not been set'
    end
    test_db_password = group_vars['dryad']['testdb']['password']
    if test_db_password.length < 1
      raise 'The dryad testdb password has not been set'
    end
  rescue
    abort "\n### Error building vagrant-dryad: The #{GROUP_VARS_FILE} exists but database passwords have not been set.\n\n  See the 'Getting Started' section of the README.md file\n\n"
  end

  # Now make sure user has entered a git repo
  begin
    repo = group_vars['dryad']['repo']
    if repo.length < 1
      raise 'The dryad repo address has not been set'
    end
  rescue
    abort "\n### Error building vagrant-dryad: The #{GROUP_VARS_FILE} exists but no repo address has been set.\n\n  See the 'Getting Started' section of the README.md file\n\n"
  end
  
  # Check if dryad.user and dryad.user_home are set
  begin
    dryad_user = group_vars['dryad']['user']
    if dryad_user.length < 1
      raise 'The dryad user has not been set'
    end
  rescue
    abort "\n### Error building vagrant-dryad: The #{GROUP_VARS_FILE} exists but is missing an entry for dryad.user.\n\n  Update your #{GROUP_VARS_FILE} to include a value for dryad.user (e.g. vagrant).\n\n  Refer to 'Getting Started' section of the README.md file and all.template\n\n"
  end
  begin
    dryad_home = group_vars['dryad']['user_home']
    if dryad_home.length < 1
      raise 'The dryad user_home has not been set'
    end
  rescue
    abort "\n### Error building vagrant-dryad: The #{GROUP_VARS_FILE} exists but is missing an entry for dryad.user_home.\n\n  Update your #{GROUP_VARS_FILE} to include a value for dryad.user_home (e.g. /home/vagrant).\n\n  Refer to 'Getting Started' section of the README.md file and all.template\n\n"
  end

#   (the old vagrant box is deprecated; please create a new one using packer-templates/ubuntu-12.04/vagrant-box-dryad.sh)
#   config.vm.box = "precise64-10g"
  # The url from where the 'config.vm.box' box will be fetched if it
  # doesn't already exist on the user's system.
#   config.vm.box_url = "http://datadryad.org/downloads/precise64-10g.box"

  config.vm.box = "dryad-ubuntu-12-04"
  # Set the name
  config.vm.define "vagrant-dryad"

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.

  # Dryad tomcat on port 9999
  config.vm.network "forwarded_port", guest: 9999, host: 9999

  # Java JPDA debugging on port 8000
  config.vm.network "forwarded_port", guest: 8000, host: 8000

  # Java JMX management on port 6969
  config.vm.network "forwarded_port", guest: 6969, host: 6969

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  config.vm.network "private_network", ip: "192.168.111.223"
  # If true, then any SSH connections made will enable agent forwarding.
  # Default value: false
  config.ssh.forward_agent = true

  # Configure the settings to use the username specified in the group vars 
  config.ssh.username = dryad_user
  config.ssh.private_key_path = "packer-templates/ubuntu-12.04/ubuntu"
  config.ssh.insert_key = false

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  config.vm.provider "virtualbox" do |vb, override|
    # Use VBoxManage to customize the VM. For example to change memory:
    vb.memory = 1024
    vb.cpus = 2
    # sync VM guest directories with the local ./sync directory
    # NOTE: the synced_folder configuration done here is meant to support 
    # dryad development with a local VM hosting the dryad codebase and running
    # the applicaiton. It is not done for the AWS provider because
    # that provider type shares guest -> host only (not bidirectionally), which is 
    # not useful for the expected development scenario.
    # See https://github.com/mitchellh/vagrant-aws/blob/master/README.md#synced-folders
    override.vm.synced_folder "sync/opt/dryad",  "/opt/dryad",  create: true
    override.vm.synced_folder "sync/home/vagrant/dryad-repo",  "/home/vagrant/dryad-repo",  create: true
  end
  config.vm.provider :aws do |aws, override|
    override.vm.box = "dummy"
    aws.access_key_id = ENV["DRYAD_AWS_ACCESS_KEY_ID"]
    aws.secret_access_key = ENV["DRYAD_AWS_SECRET_ACCESS_KEY"]
    aws.keypair_name = ENV["DRYAD_AWS_KEYPAIR_NAME"]

    # From http://cloud-images.ubuntu.com/locator/ec2/
    # us-east-1	precise	12.04 LTS	amd64	ebs	20140606	ami-a49665cc	aki-919dcaf8
    aws.ami = "ami-a69665ce"
    aws.instance_type = "t2.small"
    aws.block_device_mapping = [{ 'DeviceName' => '/dev/sda1', 'Ebs.VolumeSize' => 50 }]
    override.ssh.username = dryad_user
    override.ssh.private_key_path = ENV["DRYAD_AWS_PRIVATEKEY_PATH"]
  end
  config.vm.synced_folder ".", "/ubuntu", type: "rsync",
    rsync__exclude: [".git/","packer-templates/"]

  #
  # View the documentation for the provider you're using for more
  # information on available options.
  config.vm.provision "ansible" do |ansible|
    ansible.groups = {
      "postgresql_servers" => ["vagrant-dryad"],
      "dryad_servers" => ["vagrant-dryad"]
    }
    ansible.limit = 'all'
    ansible.playbook = "./ansible-dryad/setup.yml"
    ansible.sudo = true
    ansible.host_key_checking = false
    ansible.verbose = 'v'
  end
end
