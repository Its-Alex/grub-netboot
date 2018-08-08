# Grub2 netboot

Start a server on network with grub 

## Requirements

* Virtualbox
* Vagrant

Live image

* squashfs
* initrd
* vmlinuz

Without live image your second virtual machine will not boot
you can create these files from this [repo](https://github.com/Its-Alex/bionic-squashfs)

## How to

PXE server contain a `dhcp/tftp/http` server it is provisionned by [install-pxe-server.sh](/install-pxe-server.sh)

```
$ vagrant up pxe_server
```

Then create a folder `tftp/rescue/` in project and put live image file inside it
(with exact name as above)

```
$ vagrant up blank_server
```

Your server will now boot on live image with grub2

## Tips

`tftp` folder is a shared folder from pxe_server, this folder is exposed with tftp and http on pxe_server

Grub config is put inside `/srv/tftp/boot/grub/grub.cfg` inside pxe_server

## License

[MIT](https://fr.wikipedia.org/wiki/Licence_MIT)
