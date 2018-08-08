#!/bin/bash

set -ev

sudo apt update -y && sudo apt upgrade -y

# Generate grub netboot file
sudo update-grub
sudo grub-mknetdir --locales= --fonts= --net-directory=/srv/tftp

# Disable systemd-resolved
echo "DNSStubListener=no" | sudo tee -a /etc/systemd/resolved.conf
sudo systemctl restart systemd-resolved

# Install and setup dnsmasq
sudo apt install --no-install-recommends -y dnsmasq

sudo tee -a /etc/dnsmasq.d/pxe.conf << ENDdm
interface=eth1
bind-interfaces
no-hosts
addn-hosts=/etc/dnsmasq.d/pxe/hosts
expand-hosts
listen-address=127.0.0.1
server=8.8.8.8

dhcp-authoritative
dhcp-leasefile=/tmp/dhcp.leases

dhcp-range=192.168.0.10,192.168.0.20,255.255.255.0,12h

enable-tftp
dhcp-boot=/boot/grub/i386-pc/core.0
tftp-root=/srv/tftp
ENDdm

systemctl enable dnsmasq
systemctl restart dnsmasq

# Setup grub boot config
sudo tee /srv/tftp/boot/grub/grub.cfg << END
insmod part_msdos
insmod part_gpt
insmod lvm
insmod loopback
insmod iso9660
insmod all_video
insmod regexp
insmod biosdisk
set pager=1

set rootdir=rescue/ubuntu-18.04
linux  \$rootdir/vmlinuz initrd=\$rootdir/initrd.img netboot=nonempty boot=live nouser fetch=http://192.168.0.254/\$rootdir/filesystem.squashfs
initrd \$rootdir/initrd.img
boot
END

sudo apt install --no-install-recommends -y nginx

sudo tee /etc/nginx/sites-available/default << END
server {
  listen 80 default_server;
  listen [::]:80 default_server;
  root /srv/tftp;
  location / {
    try_files \$uri \$uri/ =404;
  }
}
END

systemctl enable nginx
systemctl restart nginx
