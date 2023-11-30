# Linux-Setup


## Prerequisites
You will need to make sure Samba, TFTP Service is already avaliable for this setup. 

Configured DHCP filename and TFTP Server pointing. If not you will need to follow this instruction first. [PXE Installation](../readme.md)

## Steps
- ****[Centos Setup](#centos-setup)****
    1. ***[Copy files from iso](#copy-files-from-Centos-iso)***
    2. ***[Config Centos Kickstart ](#centos-kickstart)***
- ****[Ubuntu Setup](#ubuntu-setup)****
    1. ***[Copy files from iso](#copy-files-from-ubuntu-iso)***
    2. ***[Config Ubuntu user-data ](#ubuntu-user-data)*** 
- ***[Config PXE server for auto installation](#config-pxe-server)***


## Centos Setup

### Copy files from Centos iso

Mount ISO to /mnt/iso

```shell
mkdir /mnt/iso

mount -o loop  /dev/cdrom /mnt/iso

cp -rf /mnt/iso /var/www/centos7 #Change it accroding to linux verison

# Create new folder to centos 7
mkdir -p /var/lib/tftpboot/bootloader/centos7
cp /var/www/centos7/isolinux/{vmlinuz,initrd.img} /var/lib/tftpboot/bootloader/centos7/
```

#### Apache Setup
---

> Add your config

```shell
vi /etc/httpd/conf.d/pxe.conf
```

> Config will be like this

```shell
Alias /centos7 /var/www/centos7/
<Directory /var/www/centos7/>
Options Indexes FollowSymLinks
Order Deny,Allow
Allow from all
</Directory>
```
---
### User password Encryption for Linux

```python
python -c 'import crypt,getpass;pw=getpass.getpass();print(crypt.crypt(pw) if (pw==getpass.getpass("Confirm: ")) else exit())'
```

### Centos Kickstart

you can find kickstart example under [Kickstart](/Linux/Centos/ks/kickstart-centos7.cfg) folder 

Then place under /var/ftp/pub/kickstart-centos7.cfg
```shell
# Create an empty file 
touch /var/ftp/pub/kickstart-centos7.cfg
# Config Kickstart
vim /var/ftp/pub/kickstart-centos7.cfg
```
```shell
# version=DEVEL
# Install OS instead of upgrade
install

# Keyboard layouts
keyboard 'us'
# Root password = "root"
rootpw --iscrypted $1$9cld8OED$TUaNsEafMdkfC2SlCm68i.
# User Password
user --name=sysadmin --groups=sysadmin --iscrypted --password=$6$7cbNpIawihELnClq$.Mxm2OvdPyIG/f/AAD2Hi60Jt.pfsv/47FhiXrQgfldCsO81JJHlDp59CJFUYDc1NbM.J.UYEtxeL5JFnMyQL1

# Use network installation
url --url="http://192.168.101.25/centos7" #7
# System language
lang en_US
# Firewall configuration
firewall --disabled
# System authorization information
auth --useshadow --passalgo=sha512
# Use graphical install(???)
text
firstboot --disable
# SELinux configuration
selinux --disabled

# Reboot after installation
reboot
# System timezone
timezone Asia/Taipei
# System bootloader configuration
bootloader --location=mbr
# Clear the Master Boot Record
zerombr
# Partition clearing information
clearpart --all --initlabel
# Disk partitioning information
part /boot --fstype="xfs" --size=1024 #7
part swap --fstype="swap" --size=1024
part / --fstype="xfs" --grow --size=1 #7

# minimal install
%packages --ignoremissing --excludedocs
@core --nodefaults
-aic94xx-firmware*
-alsa-*
-biosdevname
-btrfs-progs*
-dhcp*
-dracut-network
-iprutils
-ivtv*
-iwl*firmware
-libertas*
-kexec-tools
-plymouth*
-postfix
epel-release
wget
net-tools
nano
vim
iotop
sysstat
tree
bind-utils
ntp
curl
bash-completion
%end


# this section is for post installation script 
# it's optional
%post
echo '*/5 * * * * root /usr/sbin/ntpdate 192.168.100.99' >> /etc/crontab

# Prevent Login Delay
sed -i 's/.*UseDNS.*/UseDNS no/g' /etc/ssh/sshd_config
%end
```


## Ubuntu Setup

### Copy ISO To Apache Server
```shell
mkdir -p /var/www/ubuntu/ && mkdir -p /var/www/ubuntu//kickstart-ubuntu22.04-server/

touch /var/www/ubuntu/kickstart-ubuntu22.04-server/{meta-data,user-data}
```

```shell
# Add config to meta-data
echo "instance-id: ubuntu" > /var/www/ubuntu/kickstart-ubuntu22.04-server/meta-data
```

> ***User password Encryption for Ubuntu***

```python
python -c 'import crypt,getpass;pw=getpass.getpass();print(crypt.crypt(pw) if (pw==getpass.getpass("Confirm: ")) else exit())'
```


```shell
# Add user-data config for auto installation 
cat > /var/www/ubuntu//kickstart-ubuntu22.04-server/meta-data <<'ENDTERRAGRUNT'
#cloud-config
autoinstall:
  version: 1
  # use interactive-sections to avoid an automatic reboot
  #interactive-sections:
  #  - locale
  apt:
    # even set to no/false, geoip lookup still happens
    # geoip: true
    fallback: abort
    preserve_sources_list: false
    primary:
    - arches: [amd64, i386]
      uri: http://us.archive.ubuntu.com/ubuntu
    - arches: [default]
      uri: http://ports.ubuntu.com/ubuntu-ports
  # Add this one if you don't use user-data for multi-user setup
  identity: 
    realname: 'IT Admin'
    hostname: ubuntu
    password: $6$RGb9hkvUlaenLKX6$i6ZbkHJjgo2PBTmcSTF1yN14rJnTbeL2CbuBc3Hb9Tn/0gHgXAzDH4Ww.jxnTkA.hFUMcgtvyrw2MPh9zV6gK. # this
    username: itadmin
  user-data:
    disable_root: false
    users:
      - name: sysadmin
        passwd: $6$.u67NjXsVzODZEMQ$SwmlG2GBISBrlCCgF5GoyxNYoQt01x/ps5NSwo.R8if6rcyicHZG5fNeYiTHT4W/x8yj.ajF/6XDAm8YhHuKv/
        lock_passwd: false
        shell: /bin/bash
        groups: [sudo]
    runcmd:
      - printf 'nameserver 192.168.0.100\nnameserver 192.168.0.101\noptions timeout:1\noptions attempts:1\noptions rotate\n' > /etc/resolv.conf
      - ntpdate ntp.ark88.local
      - echo '*/5 * * * * root /usr/sbin/ntpdate 192.168.100.99' >> /etc/crontab
  package_update: true
  package_upgrade: true
  package_reboot_if_required: true
  packages:
  - bind9-dnsutils
  - curl
  - wget
  - net-tools
  - ntpdate
  timezone: Asia/Taipei
  keyboard: {layout: us, variant: ''}
  locale: en_US.UTF-8
  # interface name will probably be different
  network:
    network:
      version: 2
      ethernets:
        ens192:
          critical: true
          dhcp-identifier: mac
          dhcp4: true
  # This is for network card like ensp0s3 
        zz-all-en:
            dhcp4: true
            match:
                name: en*
  # This is for network card like eth0
        zz-all-eth:
            dhcp4: true
            match:
                name: eth*
  ssh:
    # allow password
    allow-pw: true
    # you can add keys for without using password
    authorized-keys: []
    install-server: true
  # this creates an bios_grub partition, /boot partition, and root(/) lvm volume
  storage:
    config:
    - {ptable: gpt, path: /dev/sda, wipe: superblock, preserve: false, name: '', grub_device: true, type: disk, id: disk-sda}
    - {device: disk-sda, size: 1048576, flag: bios_grub, number: 1, preserve: false, type: partition, id: partition-0}
    - {device: disk-sda, size: 1073741824, wipe: superblock, flag: '', number: 2, preserve: false, type: partition, id: partition-1}
    - {fstype: ext4, volume: partition-1, preserve: false, type: format, id: format-0}
    - {device: disk-sda, size: -1, wipe: superblock, flag: '', number: 3, preserve: false, type: partition, id: partition-2}
    - {name: ubuntu-vg, devices: [partition-2], preserve: false, type: lvm_volgroup, id: lvm_volgroup-0}
    - {name: ubuntu-lv, volgroup: lvm_volgroup-0, size: 100%, preserve: false, type: lvm_partition, id: lvm_partition-0}
    - {fstype: ext4, volume: lvm_partition-0, preserve: false, type: format, id: format-1}
    - {device: format-1, path: /, type: mount, id: mount-1}
    - {device: format-0, path: /boot, type: mount, id: mount-0}

ENDTERRAGRUNT
```


### Config PXE server
```shell

# Centos
label 1
menu label ^2) Install CentOS 7
menu default
kernel bootloader/centos7/vmlinuz
# append initrd=bootloader/centos7/initrd.img method=http://10.99.1.25/centos7 devfs=nomount
append initrd=bootloader/centos7/initrd.img ks=ftp://10.99.1.25/pub/kickstart-centos7.cfg


# Ubuntu
label 2
menu label ^2) Install Ubuntu-22.04.3 Jammy (LTS)
menu 2
kernel bootloader/ubuntu22.04-server/vmlinuz
initrd bootloader/ubuntu22.04-server/initrd
append root=/dev/ram0 ramdisk_size=1500000 ip=dhcp url=http://10.99.1.25/ubuntu/jammy-live-server-amd64.iso autoinstall ds=nocloud-net;s=http://10.99.1.25/ubuntu/kickstart-ubuntu22.04-server/ cloud-config-url=/dev/null
```