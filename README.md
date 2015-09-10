vagrant-dryad
=============

Vagrant and Ansible config for building a Dryad VM

Uses Ubuntu 12.04 64-bit, Ansible, Postgres, Java6, Tomcat6

See also [How to install Dryad](http://wiki.datadryad.org/How_To_Install_Dryad#Building_a_Virtual_Machine_with_Vagrant) for the details of the process that is automated by this codebase.

## Requirements

These applications must be installed on your host machine.  They will be used to build and run a virtual machine containing Dryad.

1. [Vagrant](http://vagrantup.com)
2. [Ansible](http://ansible.com)
3. [VirtualBox](http://virtualbox.org)

Vagrant and VirtualBox installation packages can be downloaded from their respective websites.  Ansible is a Python package with [many ways to install](http://docs.ansible.com/intro_installation.html).  One method is to use [Homebrew](http://brew.sh) (which, in turn, requires ruby) and simply `brew install ansible`.

These packages are available on many platforms, but the Dryad organization primarily uses them on recent versions of Mac OS X.

## Getting started

First, You will need to clone the repository:

    git clone git@github.com:datadryad/vagrant-dryad.git
    cd vagrant-dryad

Second, you will need to copy the `ansible-dryad/group_vars/all.template` to `ansible-dryad/group_vars/all` and set a database password and repository location.

    cp ansible-dryad/group_vars/all.template ansible-dryad/group_vars/all
    edit ansible-dryad/group_vars/all

When vagrant builds your Dryad VM, it uses the values in this file to setup the database.  You must replace the `## DB PASSWORD ##` and `## TEST DB PASSWORD ##` with new passwords. The passwords can be anything you like. They will only be used within the VM.

    db:
      host: 127.0.0.1
      port: 5432
      name: dryad_repo
      user: dryad_app
      password: ## DB PASSWORD ##
    testdb:
      host: 127.0.0.1
      port: 5432
      name: dryad_test_db
      user: dryad_test_user
      password: ## TEST DB PASSWORD ##

You must also provide the location of the Dryad source code. This is done by entering a git URL on the `repo` line. We recommended forking the master [datadryad/dryad-repo](https://github.com/datadryad/dryad-repo) to your personal GitHub account and using the URL of your fork.

    repo: ## DRYAD-REPO GIT URL or https://github.com/datadryad/dryad-repo.git ##

## Building the VM

With Virtualbox, vagrant, and ansible installed, building the virtual machine is done with

    vagrant up

This command takes a while - it's downloading a base virtual machine, installing software packages, and loading Dryad.

Sometimes provisioning fails with `fatal: [x.x.x.x] => SSH encountered an unknown error during the connection.`.  In this case simply retry with `vagrant provision`

## Accessing the Virtual Machine

After the machine has been created/provisioned successfully, you can log in with

    vagrant ssh
    
Within the virtual machine, the __vagrant__ user owns the Dryad code and installed directory.

To shut down the virtual machine, use

    vagrant halt

If you wish to destroy the virtual machine

    vagrant destroy


## Developing, Building, Testing, Deploying

By default, the Dryad repo is checked out to `/home/vagrant/dryad-repo`. This and other defaults can be changed before provisioning by editing the `ansible-dryad/group_vars/all` file.

When you log in with ssh, the VM will show some information about file locations and next steps.  In order to get Dryad up and running, these scripts need to be run in order.

```
1. Build dryad          /home/vagrant/bin/build_dryad.sh
2. Deploy dryad         /home/vagrant/bin/deploy_dryad.sh
3. Install database     /home/vagrant/bin/install_dryad_database.sh
4. Start tomcat         /home/vagrant/dryad-tomcat/bin/startup.sh
5. Rebuild SOLR indexes /home/vagrant/bin/build_indexes.sh
```

After the first build/install process, you'll only need to run build, deploy, and startup.

To create an administrative user for the local Dryad instance, run the following command after
Dryad has been deployed:

```
$ /opt/dryad/bin/dspace create-administrator
```

### Running tests

To run tests, use the `test_dryad.sh` script in `/home/vagrant/bin/`.  This script will 
1. Ensure a test database and dspace directory exist
2. Run tests with `mvn package -DskipTests=false -Ddefault.dspace.dir=...`

You can use `test_dryad -c` to clean the test environment or manually reset the test database with `install_dryad_test_database.sh`.

## Emails from Dryad

Dryad sends email notifications for many reasons, including workflow changes and user registrations. By default, `localhost` is used for the mail server. If you'd like to use a real mail server, you can reconfigure this. See `settings.xml` in [How to install Dryad](http://wiki.datadryad.org/How_To_Install_Dryad). Within the vagrant virtual machine you can simply run `run_mailserver.sh`. This script runs a "dummy" mailserver that accepts any incoming mail and displays it on the screen.

    vagrant@precise64:~$ run_mailserver.sh
    =================================================
    Starting SMTP server on localhost:25
    All email sent to this host will be printed below

    Press Control+C to exit

    Waiting for email...
    =================================================

## Debugging

If you'd like to use an external tool that supports JPDA debugging (e.g. NetBeans, Eclipse), the default JPDA port (8000) is already configured for forwarding. To start tomcat with debugging enabled, use the `/home/vagrant/dryad-tomcat/bin/startup-debug.sh` script

## Customizing the Vagrant-built VM

Beyond the above required changes, you can further customize the development environment. If you wish to customize further, it's a good idea to familiarize yourself with Vagrant's [command-line interface](http://docs.vagrantup.com/v2/cli/).

### Vagrantfile (Port forwarding)

The Vagrantfile controls VM parameters such as IP addresses and ports.

Ports 8000 and 9999 are configured by default.  8000 is for JPDA debugging if you wish to connect a remote debugger.  9999 is the default port for Dryad development hosts. You can change 9999 from the default, or forward a different host port, but you'll also need to change the corresponding port in the `ansible-dryad/group_vars/all` file. Unless you know what you're doing with Dryad's internal and external ports, it's best to leave this at 9999.

### Ansible Vars

In addition to passwords and Git repo addresses, software versions, file paths, Administrator email addresses, and more are configured in your `ansible-dryad/group_vars/all` file.  This is a YAML file that specifies configuration for your VM that you may change.

## Communication with the VM

In addition to port forwarding, the contents of this directory (The one containing the Vagrantfile) are synchronized from your host computer to the virtual machine's `/vagrant` directory. Additional synchronized directories can be added to the Vagrantfile. For example, the `dryad-bootstrap.sql` file that installs necessary content into the database is stored here, and used by the VM during installation.

When VirtualBox is used as the VM provider, vagrant is configured to sync the guest system's "/opt/dryad" and "/home/vagrant/dryad-repo" directories to subdirectories of this directory's "sync/" subdirectory.

## Upgrading your VM

As improvements are added to the vagrant/ansible configurations, you can incorporate the changes by merging in the latest changes from this repo, and running `vagrant provision`. Provisioning will bring your VM up to date without removing existing data or files. You may have to add new values to your `ansible-dryad/group_vars/all` file if they are required by newer versions of the ansible playbook, but the Vagrantfile will usually check for these important changes.

## Hacking on this repo

If you change the Vagrantfile, issue the `vagrant reload` command. Vagrant will re-read the configuration and restart your VM. It will not rebuild it from scratch. This is useful for changing ports or adding shared directories

If you change the ansible playbooks or variables, issue the `vagrant provision` command. Vagrant will run ansible and pick up your changes.

In either case, it's best to make sure the change works from start to finish. You can do this by cloning the repo and issuing `vagrant up` again. 

