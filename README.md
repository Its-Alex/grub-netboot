# Grub2 netboot

Start a server with grub 

## Requirements

* Virtualbox
* Vagrant

Live image

* squashfs
* initrd
* vmlinuz

Without live image your second virtual machine will not boot

## How to

PXE server contain a dhcp/tftp/http server it is provisionned by [`install-pxe-server.sh`](/install-pxe-server.sh)

```
$ vagrant up pxe_server
```

Then create a folder `tftp/rescue/` in project and put live image file inside it
(with exact name as above)

```
$ vagrant up blank_server
```

Your server will now boot on live image with grub2

## Usefull info

Grub config is put inside `/srv/tftp/boot/grub/grub.cfg`

`tftp` folder is sync with folder shared by pxe_server with tftp and http

## License

[MIT](https://fr.wikipedia.org/wiki/Licence_MIT)
