# Centos Setup

## Prerequisites
You will need to make sure Samba, TFTP Service is already avaliable for this setup. 

Configured DHCP filename and TFTP Server pointing. If not you will need to follow this instruction first. [PXE Installation](../readme.md)

## Steps

1. [Copy files from iso](#copy-files-from-iso)
2. [Config Centos Kickstart ]
3. Config PXE server for auto installation

## Copy files from iso

Mount ISO to /mnt/iso

```shell
mkdir /mnt/iso

mount -o loop  /dev/cdrom /mnt/iso

cp -rf /mnt/iso /var/www/centos7 #Change it accroding to linux verison
```

### Apache Setup
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
## User password Encryption for Linux

```python
python -c 'import crypt,getpass;pw=getpass.getpass();print(crypt.crypt(pw) if (pw==getpass.getpass("Confirm: ")) else exit())'
```

## Centos Kickstart

you can find kickstart example under [Kickstart](/ks/kickstart-centos7.cfg) folder 


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

## Config PXE server
```shell
label 1
menu label ^2) Install CentOS 7
menu default
kernel bootloader/centos7/vmlinuz
# append initrd=bootloader/centos7/initrd.img method=http://10.99.1.25/centos7 devfs=nomount
append initrd=bootloader/centos7/initrd.img ks=ftp://10.99.1.25/pub/kickstart-centos7.cfg
```



