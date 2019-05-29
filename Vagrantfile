Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"                    # specific box name
  # config.vm.box_version = ""          # specific box version
  config.vm.define "sample_k8s"                   # define machine name 
  config.vm.hostname = "centos7"                 # define host name
  # config.vbguest.auto_update = false
  config.vm.network "private_network", ip: "192.168.33.10"
  config.vm.network "forwarded_port", guest: 80, host: 8080
  config.vm.network "forwarded_port", guest: 22, host: 2222, id: "ssh"
  # config.vm.network :public_network, :bridge => "en0: Wi-Fi (AirPort)"
  config.vm.provider "virtualbox" do |v|
    v.cpus = 2
    v.memory = 2048
  end

  ### file sync ###
  config.vm.synced_folder ".","/home/docker",
    owner: "vagrant",
    group: "vagrant",
    mount_options: ['dmode=777','fmode=755'],
    disabled: false
    # disabled: true


  # provision
  config.vm.provision "shell", inline: <<-SHELL
    sudo chmod 777 /vagrant/init.sh
    /vagrant/init.sh
  SHELL

  config.vm.provision "docker"

end
