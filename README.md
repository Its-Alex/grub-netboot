# grub-netboot-build

🛠️ Build grub netboot binarie

Build and launch a PXE stack with grub

## Requirements

* Virtualbox
* Vagrant
  
## How to

```
$ vagrant up pxe_server
```

Server with pxe will be provisionned and ready to accept another server to connect in pxe

```
$ vagrant up blank_server
```

This server will boot on grub console

## License

[MIT](https://fr.wikipedia.org/wiki/Licence_MIT)
