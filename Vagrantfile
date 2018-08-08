Vagrant.configure("2") do |config|
    config.vm.define "pxe_server" do |pxe_server|
        pxe_server.vm.box = "debian/contrib-stretch64"

        pxe_server.vm.network "private_network", ip: "192.168.0.254", virtualbox__intnet: "pxe_lab_network"
        pxe_server.vm.synced_folder '.', '/vagrant', disabled: true
        pxe_server.vm.synced_folder 'tftp/', '/srv/tftp', create: true

        pxe_server.vm.provision "shell", path: "install-pxe-server.sh", env: {}
    end
    config.vm.define :blank_server, autostart: false do |blank_server|
        ip = "192.168.0.11"

        blank_server.vm.box = "TimGesekus/pxe-boot"
        blank_server.vm.boot_timeout = 1
        blank_server.vm.network "private_network", :adapter=>1, ip: ip, :mac => "0800278E158A" , auto_config: false, virtualbox__intnet: "pxe_lab_network"
        blank_server.vm.synced_folder '.', '/vagrant', disabled: true
        blank_server.ssh.insert_key = "false"
        blank_server.vm.provider "virtualbox" do |vb, override|
            vb.gui = false

            vb.memory = '1024'
            vb.cpus = '1'

            # Chipset needs to be piix3, otherwise the machine wont boot properly.
            vb.customize [
            "modifyvm", :id,
            "--pae", "off",
            "--chipset", "piix3",
            '--boot1', 'net',
            '--boot2', 'disk',
            '--boot3', 'none',
            '--boot4', 'none'
            ]
        end
    end
end
