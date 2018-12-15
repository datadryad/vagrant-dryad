vagrant-dryad
=============

Vagrant and Ansible config for building a Dryad VM

Uses Ubuntu 12.04 64-bit, Ansible, Postgres, Java6, Tomcat6

See also [How to install Dryad](http://wiki.datadryad.org/How_To_Install_Dryad#Building_a_Virtual_Machine_with_Vagrant) for the details of the process that is automated by this codebase.

## Requirements

These applications must be installed on your host machine.  They will be used to build and run a virtual machine containing Dryad.

1. [Vagrant](http://vagrantup.com) (version 2.0 or higher)
2. [Ansible](http://ansible.com) (version 2.0 or higher)

Vagrant installation packages can be downloaded from the respective website.  Ansible is a Python package with [many ways to install](http://docs.ansible.com/intro_installation.html).  One method is to use [Homebrew](http://brew.sh) (which, in turn, requires ruby) and simply `brew install ansible`.

These packages are available on many platforms, but the Dryad organization primarily uses them on recent versions of Mac OS X.

## Getting started

You will need to clone the repository that contains the Vagrant/Ansible settings:

    git clone https://github.com/datadryad/vagrant-dryad.git
    cd vagrant-dryad
    
## Preparing for an AWS deployment

You need to make sure that you have credentials for AWS access and ssh access.

You will need to have an access key ID and a secret access key for AWS. This is used to give your local machine permission to create VMs on the AWS infrastructure.

Then, you'll need to create a keypair for yourself. This will be used by vagrant to log in to the VMs that you create, so only you will have access to these VMs unless you explicitly grant access to others. To create the keypair, log in to the aws.amazon.com console, then go to the EC2 dashboard. Click on "Key Pairs" on the left sidebar under "Network and Security." Then create a new key pair for yourself. The private key file `xxx.pem` should automatically download. Save this file somewhere safe on your machine, and note the path.

Now you'll need to set the environment variables that the Vagrantfile needs. In your `.bash_profile` (or wherever you set your environment variables), add the following values:

```
# Amazon credentials
export DRYAD_AWS_ACCESS_KEY_ID=<your access key ID, in single quotes>
export DRYAD_AWS_SECRET_ACCESS_KEY=<your secret access key, in single quotes>
export DRYAD_AWS_KEYPAIR_NAME=<the name of your keypair, in single quotes>
export DRYAD_AWS_PRIVATEKEY_PATH=<the full path to your .pem.txt file, (e.g. ~/.ssh/user.pem.txt) in single quotes>
export DRYAD_AWS_VM_NAME=<the name you want the VM to have in the EC2 console>
```

`DRYAD_AWS_ACCESS_KEY_ID` and `DRYAD_AWS_SECRET_ACCESS_KEY` are the credentials that the AWS machine will use to connect with other AWS services. In most cases, these can be your personal AWS credentials.

Reload your settings when you're done: `source ~/.bash_profile`.

Verify that you have the correct path specified: `more $DRYAD_AWS_PRIVATEKEY_PATH` should give you a cryptic key starting with `-----BEGIN RSA PRIVATE KEY-----`. If not, double-check your path in your .bash_profile and source it again.


## Creating a database

A local database will be created, but you are welcome to use an external database instead. 

To create a local database, obtain a copy of a Dryad sql file. When your virtual machine is running, use the `import_pg_dump.sh` script to populate your local database.

To create a database using Amazon RDS, login to an existing Dryad machine, and run the utility script to create a new database:

    dryad-utils/aws-tools/db-create-new.sh <db-hostname> <db-password>

## Configuring Dryad's database and assetstore

Copy the `ansible-dryad/group_vars/all.template` to `ansible-dryad/group_vars/all` and set a database password and repository location.

When vagrant builds your Dryad VM, it uses the values in this file to setup the database.  You must replace the all entries in the file that are surrounded by double hash marks (`##`)
- `repo` is the GitHub repository that will be used to download the Dryad codebase. We recommended forking the master [datadryad/dryad-repo](https://github.com/datadryad/dryad-repo) to your personal GitHub account and using the URL of your fork. 
- `aws.regionName` is the region that the AWS machines will be created in. 
- `aws.bucketName` is the name of the S3 bucket that will be used for the assetstore.
- `assetstoreIncoming` should be set to `1`
- `db.host` If you are using an Amazon RDS database that contains Dryad data, this should be set to the address of that RDS instance.

## Building a cloud VM with Amazon AWS

Install the Vagrant-aws plugin: `vagrant plugin install vagrant-aws`

Then download the base box: `vagrant box add dummy https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box`

Verify that you have the correct path specified: `more $DRYAD_AWS_PRIVATEKEY_PATH` should give you a cryptic key starting with `-----BEGIN RSA PRIVATE KEY-----`. If not, double-check your path in your .bash_profile and source it again.

Now run `vagrant up` to create a vagrant VM at Amazon. You should be able to find the public IP and public DNS settings for your instance in the EC2 dashboard: find your instance by clicking on Instances in the left sidebar and selecting your instance.

*Remember*, AWS will charge for any time that the machine is running. Although these charges are minimal, you may wish to avoid them. You may halt the machine whenever you are not using it. (`vagrant halt`)

## Accessing the Virtual Machine

After the machine has been created/provisioned successfully, you can log in with

    vagrant ssh
    
Within the virtual machine, the __ubuntu__ user owns the Dryad code and installed directory.

To shut down the virtual machine, use

    vagrant halt

If you wish to destroy the virtual machine, first go into AWS OpsWorks, and remove it. Then

    vagrant destroy

## Developing, Building, Testing, Deploying the Dryad code

By default, the Dryad repo is checked out to `/home/ubuntu/dryad-repo`. This and other defaults can be changed before provisioning by editing the `ansible-dryad/group_vars/all` file.

When you log in with ssh, the VM will show some information about file locations and next steps.  In order to get Dryad up and running, these scripts need to be run in order.

```
1. Build dryad          /home/ubuntu/bin/build_dryad.sh
2. Deploy dryad         /home/ubuntu/bin/deploy_dryad.sh
3. Start tomcat         /home/ubuntu/dryad-tomcat/bin/startup.sh
4. Rebuild SOLR indexes /home/ubuntu/bin/build_indexes.sh
```

After the first build/install process, you'll only need to run redeploy_dryad.sh

To create an administrative user for the local Dryad instance, run the following command after
Dryad has been deployed:

```
$ /opt/dryad/bin/dspace create-administrator
```

### Running tests

To run tests, use the `test_dryad.sh` script in `/home/ubuntu/bin/`.  This script will 
1. Ensure a test database and dspace directory exist
2. Run tests with `mvn package -DskipTests=false -Ddefault.dspace.dir=...`

You can use `test_dryad -c` to clean the test environment or manually reset the test database with `install_dryad_test_database.sh`.

## Emails from Dryad

Dryad sends email notifications for many reasons, including workflow changes and user registrations. Before email will be sent, the configuration for default.mail.server.disabled will need to be set to "false" in the maven settings.xml.

By default, `localhost` is used for the mail server. If you'd like to use a real mail server, you can reconfigure this. See `settings.xml` in [How to install Dryad](http://wiki.datadryad.org/How_To_Install_Dryad). Within the vagrant virtual machine you can simply run `run_mailserver.sh`. This script runs a "dummy" mailserver that accepts any incoming mail and displays it on the screen.

    ubuntu@precise64:~$ run_mailserver.sh
    =================================================
    Starting SMTP server on localhost:25
    All email sent to this host will be printed below

    Press Control+C to exit

    Waiting for email...
    =================================================

*Note for AWS deployments:* To prevent spam, many Amazon-based IP addresses are blocked or delayed by standard email providers. For testing purposes, it is best to used the dummy mailserver described above. For production machines, it is better to assign an Elastic IP address and then request that Amazon "remove email restrictions" for that IP address.

## Debugging

If you'd like to use an external tool that supports JPDA debugging (e.g. NetBeans, Eclipse), the default JPDA port (8000) is already configured for forwarding. To start tomcat with debugging enabled, use the `/home/ubuntu/dryad-tomcat/bin/startup-debug.sh` script

## Customizing the Vagrant-built VM

Beyond the above required changes, you can further customize the development environment. If you wish to customize further, it's a good idea to familiarize yourself with Vagrant's [command-line interface](http://docs.vagrantup.com/v2/cli/).

### Vagrantfile (Port forwarding)

The Vagrantfile controls VM parameters such as IP addresses and ports.

Ports 8000 and 9999 are configured by default.  8000 is for JPDA debugging if you wish to connect a remote debugger.  9999 is the default port for Dryad development hosts. You can change 9999 from the default, or forward a different host port, but you'll also need to change the corresponding port in the `ansible-dryad/group_vars/all` file. Unless you know what you're doing with Dryad's internal and external ports, it's best to leave this at 9999.

### Ansible Vars

In addition to passwords and Git repo addresses, software versions, file paths, Administrator email addresses, and more are configured in your `ansible-dryad/group_vars/all` file.  This is a YAML file that specifies configuration for your VM that you may change.

## Communication with the VM

In addition to port forwarding, the contents of this directory (The one containing the Vagrantfile) are synchronized from your host computer to the virtual machine's `/ubuntu` directory. Additional synchronized directories can be added to the Vagrantfile. For example, the `dryad-bootstrap.sql` file that installs necessary content into the database is stored here, and used by the VM during installation.

## Upgrading your VM

As improvements are added to the vagrant/ansible configurations, you can incorporate the changes by merging in the latest changes from this repo, and running `vagrant provision`. Provisioning will bring your VM up to date without removing existing data or files. You may have to add new values to your `ansible-dryad/group_vars/all` file if they are required by newer versions of the ansible playbook, but the Vagrantfile will usually check for these important changes.

## Hacking on this repo

If you change the Vagrantfile, issue the `vagrant reload` command. Vagrant will re-read the configuration and restart your VM. It will not rebuild it from scratch. This is useful for changing ports or adding shared directories

If you change the ansible playbooks or variables, issue the `vagrant provision` command. Vagrant will run ansible and pick up your changes.

In either case, it's best to make sure the change works from start to finish. You can do this by cloning the repo and issuing `vagrant up` again. 

