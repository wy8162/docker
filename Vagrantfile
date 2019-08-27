# -*- mode: ruby -*-
# vi: set ft=ruby :
 
# Multi-VM Configuration: Builds Web, Application, and Database Servers using JSON config file
# Configures VMs based on Hosted Chef Server defined Environment and Node (vs. Roles)
# Author: Gary A. Stafford

# programmaticponderings.wordpress.com/2014/02/27/multi-vm-creation-using-vagrant-and-json/
#

# Modified by Yang Wang

# read vm
nodes_config = (JSON.parse(File.read("vnodes.json")))['nodes']
 
VAGRANTFILE_API_VERSION = "2"
 
#Vagrant.require_plugin "vagrant-omnibus"
 
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  #config.vm.box     = "oraclelinux6.5"
  #config.vm.box_url = "https://storage.us2.oraclecloud.com/v1/istoilis-istoilis/vagrant/oel65-64.box"
  #config.vm.box="devserver-centos6.5"
  #config.vm.box="dt-centos6"
  config.vm.box   = "williamyeh/ubuntu-trusty64-docker"
  config.vm.box_version = ">=1.10"
 
  # This is needed to make sure chef-solo is installed so that we can use chef provisioning
  # Install vagrant-omnibus plugin if needed
  # $ vagrant plugin install vagrant-omnibus
  #
  # Otherwise, need to manually install it as below:
  #     root@intro:~# cd ~
  #     root@intro:~# curl -L https://www.opscode.com/chef/install.sh | bash
  #     root@intro:~# chef-solo -v

  # Not to install chef. No need at this time. //Yang Wang
  # config.omnibus.chef_version = :latest
  
  # Docker provisioner - no arguments, so just to install docker in the VM
  # https://docs.vagrantup.com/v2/provisioning/docker.html
  config.vm.provision "docker" do |d|
  end
  
  nodes_config.each do |node|
    node_name   = node[0] # name of node
    node_values = node[1] # content of node
 
    config.vm.define node_name do |nodeconfig|    
      # configures all forwarding ports in JSON array
      ports = node_values['ports']
      ports.each do |port|
        nodeconfig.vm.network :forwarded_port,
          host:  port[':host'],
          guest: port[':guest'],
          id:    port[':id']
      end
 
      nodeconfig.vm.hostname = node_values[':node']
      nodeconfig.vm.network :private_network, ip: node_values[':ip']
 
      # Setup project directories
      nodeconfig.vm.synced_folder "c:/development", "/development"
 
      nodeconfig.vm.provider :virtualbox do |vb|
        vb.name = node_name
        vb.customize ["modifyvm", :id, "--memory", node_values[':memory']]
        vb.customize ["modifyvm", :id, "--name", node_values[':node']]
		vb.customize ["modifyvm", :id, "--cpus", node_values[':cpus']]
      end
      
      # Set up the Vagrant to use my SSH key.
      # From: stackoverflow.com/questions/14715678/vagrant-insecure-by-default
      #       by donnoman.
      nodeconfig.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'" # avoids 'stdin: is not a tty' error.

      nodeconfig.ssh.private_key_path = ["#{ENV['HOME']}/.ssh/id_rsa","#{ENV['HOME']}/.vagrant.d/insecure_private_key"]

	  #nodeconfig.vm.provision "file", source: "~/.ssh/id_rsa.pub", destination: "/home/vagrant/.ssh/authorized_keys"
    end
  end
end