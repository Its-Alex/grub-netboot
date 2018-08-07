#!/bin/bash

set -ev

sudo apt update -y && sudo apt upgrade -y && sudo apt install --no-install-recommends -y dnsmasq

# Generate grub netboot file
sudo grub-mknetdir --locales= --fonts= --net-directory=/srv/tftp

# Disable systemd-resolved
echo "DNSStubListener=no" | sudo tee -a /etc/systemd/resolved.conf
sudo systemctl restart systemd-resolved

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
tftp-secure
ENDdm

sudo tee -a /boot/grub/grub.cfg << ENDdm
insmod part_msdos
insmod part_gpt
insmod lvm
insmod loopback
insmod iso9660
insmod all_video
insmod regexp
insmod biosdisk
set pager=1

submenu 'Detect systems on local disks' {
	for dev in (*); do
		# List available ISOs
		casper_isofiles=
		for file in \$dev/linux-iso/*.iso; do
			if [ -f \$file ]; then
				loopback scanloop \$file
				if [ -d (scanloop)/casper ]; then
					regexp --set isofile "\\(.*\\)(.*)" \$file
					casper_isofiles="\$isofile \$casper_isofiles"
				fi
			fi
		done
		if [ ! -z \$casper_isofiles ]; then
			probe --set uuid -u \$dev
			submenu "Autodetected ISOs on \$dev" \$uuid "\$casper_isofiles" {
				set uuid="\$2"
				set casper_isofiles="\$3"

				for file in \$casper_isofiles; do
					menuentry "Boot \$file" \$file \$uuid {
						set isofile="\$2"
						set uuid="\$3"
						search --no-floppy --fs-uuid --set=root \$uuid
						loopback loop \$isofile

						set kernel='vmlinuz'
						if [ ! -f (loop)/casper/\$kernel ]; then
							set kernel='vmlinuz.efi'
						fi

						linux  (loop)/casper/\$kernel locale=fr_FR bootkbd=fr console-setup/layoutcode=fr iso-scan/filename=\$isofile boot=casper file=/cdrom/preseed/ubuntu.seed noprompt ro splash noeject toram -- quiet
						initrd (loop)/casper/initrd.lz
					}
				done
			}
		fi

		# List grub configuration files
		grubcfg=
		for file in \$dev/boot/grub/grub.cfg \$dev/grub/grub.cfg; do
			if [ -f \$file ]; then
				grubcfg="\$file \$grubcfg"
			fi
		done
		if [ ! -z \$grubcfg ]; then
			probe --set uuid -u \$dev
			submenu "Autodetected GRUB on \$dev" \$uuid "\$grubcfg" {
				set uuid="\$2"
				set grubcfg="\$3"

				# Add entries from the on disk grub configuration
				for file in \$grubcfg; do
					menuentry 'Chainload the Grub' \$file \$uuid {
						set file="\$2"
						set uuid="\$3"
						search --no-floppy --fs-uuid --set=root \$uuid
						configfile \$file
					}

					submenu "Entries from \$file" \$file {
						set file="\$2"
						extract_entries_source \$file
					}
				done
			}
		fi

		# List available kernels
		kernels=
		for file in \$dev/boot/vmlinuz-* \$dev/vmlinuz-*; do
			if [ -f \$file ]; then
				kernels="\$file \$kernels"
			fi
		done
		if [ ! -z \$kernels ]; then
			probe --set uuid -u \$dev
			submenu "Autodetected Linux kernels on \$dev" \$uuid "\$kernels" {
				set uuid="\$2"
				set kernels="\$3"

				# Add entries for autodetected linux kernels
				for file in \$kernels; do
					regexp --set version '.*/vmlinuz-(.*)' \$file
					regexp --set version '.*/vmlinuz-(.*).efi.signed' \$file

					menuentry "Autodetected Linux \$file" \$file \$uuid \$version {
						set file="\$2"
						set uuid="\$3"
						set version="\$4"

						search --no-floppy --fs-uuid --set=root \$uuid
						linux \$file root=UUID=\$uuid ro quiet splash
						initrd /boot/initrd.img-\$version
					}

					menuentry "Autodetected Linux \$file (single)" \$file \$uuid \$version {
						set file="\$2"
						set uuid="\$3"
						set version="\$4"

						search --no-floppy --fs-uuid --set=root \$uuid
						linux \$file root=UUID=\$uuid ro single nomodeset
						initrd /boot/initrd.img-\$version
					}
				done
			}
		fi
	done
}

submenu 'Debian installers' {
	for directory in /debian/stretch/amd64 /debian/stretch/i386; do
		menuentry "Launch installer \$directory" \$directory {
			set rootdir="\$2"
			linux  \$rootdir/linux nomodeset initrd=\$rootdir/initrd.gz ro noeject locale=fr_FR bootkbd=fr console-setup/layoutcode=fr --- quiet
			initrd \$rootdir/initrd.gz \$rootdir/firmware.cpio.gz
		}
		menuentry "Launch installer \$directory in rescue mode" \$directory {
			set rootdir="\$2"
			linux  \$rootdir/linux nomodeset initrd=\$rootdir/initrd.gz ro noeject locale=fr_FR bootkbd=fr console-setup/layoutcode=fr rescue/enable=true debconf/priority=critical --- quiet
			initrd \$rootdir/initrd.gz \$rootdir/firmware.cpio.gz
		}
		menuentry "Launch installer \$directory in rescue mode with SSH" \$directory {
			set rootdir="\$2"
			linux  \$rootdir/linux nomodeset initrd=\$rootdir/initrd.gz ro noeject locale=fr_FR bootkbd=fr console-setup/layoutcode=fr rescue/enable=true debconf/priority=critical anna/choose_modules=network-console --- quiet
			initrd \$rootdir/initrd.gz \$rootdir/firmware.cpio.gz
		}
	done
}

submenu 'Ubuntu installers' {
	for directory in /ubuntu/xenial/amd64 /ubuntu/xenial/i386; do
		menuentry "Launch installer \$directory" \$directory {
			set rootdir="\$2"
			linux  \$rootdir/linux nomodeset initrd=\$rootdir/initrd.gz ro noeject locale=fr_FR bootkbd=fr console-setup/layoutcode=fr --- quiet
			initrd \$rootdir/initrd.gz
		}
		menuentry "Launch installer \$directory in rescue mode" \$directory {
			set rootdir="\$2"
			linux  \$rootdir/linux nomodeset initrd=\$rootdir/initrd.gz ro noeject locale=fr_FR bootkbd=fr console-setup/layoutcode=fr rescue/enable=true debconf/priority=critical --- quiet
			initrd \$rootdir/initrd.gz
		}
		menuentry "Launch installer \$directory in rescue mode with SSH" \$directory {
			set rootdir="\$2"
			linux  \$rootdir/linux nomodeset initrd=\$rootdir/initrd.gz ro noeject locale=fr_FR bootkbd=fr console-setup/layoutcode=fr rescue/enable=true debconf/priority=critical anna/choose_modules=network-console --- quiet
			initrd \$rootdir/initrd.gz
		}
	done
}

menuentry 'SliTaz 4.0 - i386' {
	set rootdir="/slitaz"
	linux  \$rootdir/bzImage lang=fr_FR kmap=fr-latin1 rw root=/dev/null autologin nomodeset
	initrd \$rootdir/rootfs4.gz \$rootdir/rootfs3.gz \$rootdir/rootfs2.gz \$rootdir/rootfs1.gz
}

submenu 'Tools' {
	menuentry 'System setup' {
		fwsetup
	}
	menuentry 'Memtest86+ (BIOS)' {
		set binfile="/memtest86+.elf"
		search --no-floppy --set -f \$binfile
		knetbsd \$binfile
	}
	menuentry 'Memtest86 (EFI)' {
		set binfile="/MEMTEST86/BOOTX64.efi"
		search --no-floppy --set -f \$binfile
		chainloader \$binfile
	}
}
ENDdm

sudo chown dnsmasq:nogroup -R /srv/tftp

systemctl restart dnsmasq
systemctl enable dnsmasq