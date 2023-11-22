# PXE Server Installation

## Installation Steps 
1. ***[Configure DHCP Server](#config-dhcp)***
2. ***PXE Server Installation***
    - ***[Install dependency packages](#dependency-packages-installtion)***
    - ***[tftp setup](#TFTP-setup)***
    - ***[ftp setup](#ftp-setup)***
    - ***[samba setup](#samba-setup)***
    - ***[apache setup](#apache-setup)***
3. ***[Windows Setup](/Windows/readme.md)***
    1. ***[Install ADK Tool](/Windows/readme.md/#install-adk-tool-for-windows-1011)***
    2. ***[How to enscapsulate windows PE](/Windows/readme.md/#how-to-enscapsulate-windows-pe-preinstall-environment)***
    3. ***[How to sysprep](/Windows/readme.md/#how-to-sysprep)***
        - ***[Config Unattend XML](/Windows/readme.md/#config-unattend-file)***
        - ***[Run Sysprep](/Windows/readme.md/#run-sysprep)***
            - ***[Why sysprep](/Windows/readme.md/#why-sysprep)***
            - ***[Install OEM Information and Logo](/Windows/readme.md/#step-1-install-oem-information-and-logo)***
            - ***[Install the Drivers and Apps](/Windows/readme.md/#step-2-install-the-drivers-and-apps)***
            - ***[Disable Telemetry and Data Collection in Windows 10](/Windows/readme.md/#step-3-disable-telemetry-and-data-collection-in-windows-10)***
            - ***[Install Windows Security Update in Audit Mode](/Windows/readme.md/#step-4-install-windows-security-update-in-audit-mode)***
            - ***[Uninstall Built-in Microsoft Store Apps](/Windows/readme.md/#step-5-uninstall-built-in-microsoft-store-apps)***
            - ***[Setup Networks & Clean Caches ](/Windows/readme.md/#setup-networks--clean-caches)***
            - ***[Finalize Sysprep](/Windows/readme.md/#finalize)***
    4. ***[Capture Image (Using DISM after Generalize)](/Windows/readme.md/#capture-image-using-dism-after-generalize)***
    5. ***[Convert Wim To ISO](/Windows/readme.md/#convert-wim-to-iso)***
    6. ***[Add Windows Update Packages](/Windows/readme.md/#Add-Windows-Update-packages)***
    7.  ***[Troubleshooting](/Windows/readme.md/#windows-troubleshooting)***
4. ***[Centos Setup](/Linux/readme.md/#Centos-Setup)***
    - ***[Copy files from iso](/Linux/readme.md/#copy-files-from-iso)***
    - ***[Config Centos Kickstart ](/Linux/readme.md/#centos-kickstart)***
    - ***[Config PXE server for auto installation](/Linux/readme.md/#config-pxe-server)***


---
## Config DHCP 

> For this tutorial, I'm using Windows DHCP server. 

![alt text](/screenshots/dhcp_setup.png)

## Dependency packages installtion
```shell
# For Centos Initial Setup
yum install -y epel-release
# Install Packages as you need 
yum install -y htop iotop sysstat vim nano yum-utils bind-utils net-tools curl wget 
# Install Samba TFTP FTP HTTPD PXE
yum install -y tftp-server syslinux vsftpd httpd samba samba-client samba-common
```

### TFTP setup (PXE)
---
> Copy PXE boot menu from Syslinux 

```shell
cp -f /usr/share/syslinux/{chain.c32,mboot.c32,memdisk,menu.c32,pxelinux.0} /var/lib/tftpboot

mkdir /var/lib/tftpboot/bootloader

mkdir -p /var/lib/tftpboot/pxelinux.cfg

touch /var/lib/tftpboot/pxelinux.cfg/default
```
>  TFTP Folder Structure

```shell
.
├── bootloader
│   ├── centos7
│   │   ├── initrd.img                      # Copy from /mnt/iso/isolinux/initrd.img
│   │   └── vmlinuz                         # Copy from /mnt/iso/isolinux/vmlinuz
│   ├── centos8
│   │   ├── initrd.img                      # Copy from /mnt/iso/isolinux/initrd.img
│   │   └── vmlinuz                         # Copy from /mnt/iso/isolinux/vmlinuz
│   ├── centos9
│   │   ├── initrd.img                      # Copy from /mnt/iso/isolinux/initrd.img
│   │   └── vmlinuz                         # Copy from /mnt/iso/isolinux/vmlinuz
│   ├── preboot
│   │   └── Win10_PE.iso
│   ├── ubuntu18.04-server
│   │   ├── initrd
│   │   └── vmlinuz
│   ├── win10
│   │   └── win-10-pe.iso
│   ├── win11
│   │   └── win-11-pe.iso
│   ├── winserver2012r2
│   │   └── win-server-2012r2-pe.iso
│   ├── winserver2016
│   │   └── win-server-2016-pe.iso
│   └── winserver2019
│       └── win-server-2019-pe.iso
├── chain.c32
├── mboot.c32
├── memdisk
├── menu.c32
├── pxelinux.0
└── pxelinux.cfg
    └── default

```
> This is example config of pxelinux.cfg/default


```shell
vi /var/lib/tftpboot/pxelinux.cfg/default
```

```shell
default menu.c32
prompt 0
timeout 300
ONTIMEOUT 1

menu title ########## PXE Boot Menu ##########

label 1
menu label ^1) Boot From Hard Drive
menu default
localboot 0

label 2
menu label ^2) Install CentOS 7
menu 2
kernel bootloader/centos7/vmlinuz
# append initrd=bootloader/centos7/initrd.img method=http://10.99.1.25/centos7 devfs=nomount
append initrd=bootloader/centos7/initrd.img ks=ftp://10.99.1.25/pub/kickstart-centos7.cfg

label 3
menu label ^3) Install CentOS 8
menu 3
kernel bootloader/centos8/vmlinuz
# append initrd=bootloader/centos8/initrd.img method=http://10.99.1.25/centos8 devfs=nomount
append initrd=bootloader/centos8/initrd.img inst.ks=ftp://10.99.1.25/pub/kickstart-centos8.cfg

label 4
menu label ^4) Install CentOS 9
menu 4
kernel bootloader/centos9/vmlinuz
# append initrd=bootloader/centos8/initrd.img method=http://10.99.1.25/centos8 devfs=nomount
append initrd=bootloader/centos9/initrd.img inst.ks=ftp://10.99.1.25/pub/kickstart-centos9.cfg

label 5
menu label ^5) Install Ubuntu18.04.02-Server
kernel bootloader/ubuntu18.04-server/casper/vmlinuz
# append initrd=bootloader/ubuntu18.04-server/initrd.img method=http://10.99.1.25/ubuntu18.04-server devfs=nomount
append initrd=bootloader/ubuntu18.04-server/casper/initrd 
ks=nfs:192.168.116.41:/nfsshare/ubuntu18/preseed/ubuntu.seed --- quiet

label 6
menu label ^6) Install Windows Server 2019
kernel memdisk
append iso raw initrd=bootloader/winserver2019/win-server-2019-pe.iso

label 7
menu label ^7) Install Windows Server 2016
kernel memdisk
append iso raw initrd=bootloader/winserver2016/win-server-2016-pe.iso

label 8
menu label ^8) Install Windows 10 Pro (Domain Joined)
kernel memdisk
append iso raw initrd=bootloader/win10/win-10-pe.iso

label 9
menu label ^9) Install Windows 11 Pro (Domain Joined)
kernel memdisk
append iso raw initrd=bootloader/wins11/win-11-pe.iso

label 10
menu label ^10) Boot Win10 (Maintenance Only)
kernel memdisk
append iso raw initrd=bootloader/preboot/Win10_PE.iso

label 11
menu label ^11) Install ESXI 6.7 (For Dell Server)
kernel bootloader/esxi6.7-dell/mboot.c32
append -c bootloader/esxi6.7-dell/boot.cfg

label 12
menu label ^12) Install ESXI 8.0u2
kernel bootloader/esxi8u2/mboot.c32
append -c bootloader/esxi8u2/boot.cfg

```

> You can change your ***folder*** directory in 

```shell
vi /etc/xinetd.d/tftp
```
---

```shell

# default: off
# description: The tftp server serves files using the trivial file transfer \
#       protocol.  The tftp protocol is often used to boot diskless \
#       workstations, download configuration files to network-aware printers, \
#       and to start the installation process for some operating systems.
service tftp
{
        socket_type             = dgram
        protocol                = udp
        wait                    = yes
        user                    = root 
        server                  = /usr/sbin/in.tftpd
        server_args             = -s /var/lib/tftpboot # Change directory if you want 
        disable                 = yes
        per_source              = 11
        cps                     = 100 2
        flags                   = IPv4
}
```
### FTP setup
---
> ***For this tutorial I'll only use root to do all the stuff, you can skip this step if you want***

> Create Users
---
```shell
# This is optional for this tutorial
# Create user and add permission to FTP
adduser sysadmin
echo "!QAZ2wsx" | passwd --stdin sysadmin

# This is Optional for this tutorial
# Give permission to folder if needed 
chmod +x -R /home/smbshare
chown -R sysadmin:sysadmin /home/smbshare
```
> Add Users to FTP allow list

```shell
# This is optional for this tutorial
echo "sysadmin" >> /etc/vsftpd/user_list
```
> Config FTP

```shell
# Disable for security purpose
# For this tutorial we enable

sed -i -E 's/anonymous\_enable\=.*/anonymous_enable=NO/g' /etc/vsftpd/vsftpd.conf
```


### Samba Setup
---
> Add Samba Directory for PXE Installation Folder

```shell
cat <<EOF >> /etc/samba/smb.conf
# add this one 
[install]
        comment = Installation Media
        path = /home/smbshare
        public = yes
        writable = yes 
        printable = no 
        browseable = yes
EOF
```

> Then make folder in /home/smbshare

```shell
mkdir /home/smbshare

# if you're not root user make sure you give the right permission 
chown -R root:root /home/smbshare
chmod -R +x /home/smbshare
```

```shell
# Create User for smb
echo -e "P@ssw0rd\nP@ssw0rd"smbpasswd -a root
```

> Samba Folder Structure is like this

```shell
.
├── autoinstall_conf
│   ├── assettag.txt            # This is for matching Service Tags To Asset Tags
│   ├── rename.ps1              # User asssettag.txt to rename the computer
│   ├── win-10.xml              # File for auto installation
│   ├── win-server-2016.xml     # File for auto installation
│   └── win-server-2019.xml     # File for auto installation
├── software_packages           # Softwares for wnidows installation
├── win-10                      # Windows 10 Custom Images 
├── win-11                      # Windows 11 Custom Images
├── win-server-2019             # Windows Server 2019 Standard 
├── win-server-2016             # Windows Server 2016 Standard 
└── win-server-2012r2           # Windows Server 2012r2 Standard 

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

## Tips
---

> ***User password Encryption for Centos***

```python
python -c 'import crypt,getpass;pw=getpass.getpass();print(crypt.crypt(pw) if (pw==getpass.getpass("Confirm: ")) else exit())'
```

> ***Services Restart***

```shell
# Restart Services
systemctl restart httpd smb nmb vsftpd tftp
# Load Services when startup
systemctl enable httpd smb nmb vsftpd tftp
```

> ***Disable Selinux***

```shell
sed -i -E "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
```

> ***Firewall Tips***

```shell
# Get services list
firewall-cmd --get-services
# You can add firewall by services
sudo firewall-cmd --zone=public --add-service=http --permanent
sudo firewall-cmd --zone=public --add-service=samba --permanent
sudo firewall-cmd --zone=public --add-service=tftp --permanent
sudo firewall-cmd --zone=public --add-service=ftp --permanent
sudo firewall-cmd --zone=public --add-service=samba --permanent
sudo firewall-cmd --zone=public --add-service=ssh --permanent

# Reload firewall 
sudo firewall-cmd --reload
```
