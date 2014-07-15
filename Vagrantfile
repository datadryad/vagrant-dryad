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

  group_vars = YAML::load(File.open(GROUP_VARS_FILE))
  # Make sure user has customized the template file.
  # Use ruby exception handling to catch errors
  begin
    db_password = group_vars['dryad']['db']['password']
    if db_password.length < 1
      raise 'The dryad db password has not been set'
    end
  rescue
    abort "\n### Error building vagrant-dryad: The #{GROUP_VARS_FILE} exists but no db password has been set.\n\n  See the 'Getting Started' section of the README.md file\n\n"
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

  config.vm.box = "precise64-10g"
  # The url from where the 'config.vm.box' box will be fetched if it
  # doesn't already exist on the user's system.
  config.vm.box_url = "http://datadryad.org/downloads/precise64-10g.box"

  # Set the name
  config.vm.define "vagrant-dryad"

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.

  # Dryad tomcat on port 9999
  config.vm.network "forwarded_port", guest: 9999, host: 9999

  # Java JPDA debugging on port 8000
  config.vm.network "forwarded_port", guest: 8000, host: 8000
  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  config.vm.network "private_network", ip: "192.168.111.223"
  # If true, then any SSH connections made will enable agent forwarding.
  # Default value: false
  config.ssh.forward_agent = true

  # sync VM directories with local ./sync directory
  config.vm.synced_folder "sync/opt/dryad",  "/opt/dryad",  create: false
  config.vm.synced_folder "sync/home/vagrant/dryad-repo",  "/home/vagrant/dryad-repo",  create: false

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  config.vm.provider "virtualbox" do |vb|
    # Use VBoxManage to customize the VM. For example to change memory:
    vb.customize ["modifyvm", :id, "--memory", "4096"]
  end
  #
  # View the documentation for the provider you're using for more
  # information on available options.
  config.vm.provision "ansible" do |ansible|
    ansible.inventory_path = "./vagrant_inventory"
    ansible.limit = 'all'
    ansible.playbook = "./ansible-dryad/setup.yml"
    ansible.sudo = true
    ansible.host_key_checking = false
  end
end

