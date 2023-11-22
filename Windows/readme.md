# Windows PXE Setup

## Prerequisites 

You will need to make sure Samba, TFTP Service is already avaliable for this setup. 

Configured DHCP filename and TFTP Server pointing. If not you will need to follow this instruction first. [PXE Installation](../readme.md)

## Step by step

1. ***[Install ADK Tool](#install-adk-tool-for-windows-1011)***
2. ***[How to enscapsulate windows PE](#how-to-enscapsulate-windows-pe-preinstall-environment)***
3. ***[How to sysprep](#how-to-sysprep)***
    1. ***[Config Unattend XML](#config-unattend-file)***
    2. ***[Run Sysprep](#run-sysprep)***
        - ***[Why sysprep](#why-sysprep)***
        - ***[Install OEM Information and Logo](#step-1-install-oem-information-and-logo)***
        - ***[Install the Drivers and Apps](#step-2-install-the-drivers-and-apps)***
        - ***[Disable Telemetry and Data Collection in Windows 10](#step-3-disable-telemetry-and-data-collection-in-windows-10)***
        - ***[Install Windows Security Update in Audit Mode](#step-4-install-windows-security-update-in-audit-mode)***
        - ***[Uninstall Built-in Microsoft Store Apps](#step-5-uninstall-built-in-microsoft-store-apps)***
        - ***[Setup Networks & Clean Caches ](#setup-networks--clean-caches)***
        - ***[Finalize Sysprep](#finalize)***
4. ***[Capture Image (Using DISM after Generalize)](#capture-image-using-dism-after-generalize)***
5. ***[Convert Wim To ISO](#convert-wim-to-iso)***
6. ***[Add Windows Update Packages](#Add-Windows-Update-packages)***
7. ***[Troubleshooting](#windows-troubleshooting)***
## Install ADK Tool (For Windows 10/11)

- Download the [ADK Tool](https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install).
- Run the **adksetup.exe** installer.
- Follow the installation steps, ensuring that the components required for Windows Preinstallation Environment (WinPE) are selected.
- Run the **adkwinpesetup.exe** installer.
- Verify the installation by checking the installed components.


[Download Link](https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install)
---
![Alt text](/screenshots/adk_install.png)

> Installation ***adksetup.exe***

![Alt text](/screenshots/adk-tool-installation-1.png)

![Alt text](/screenshots/adk-tool-installation-2.png)

![Alt text](/screenshots/adk-tool-installation-3.png)

> Installation ***adkwinpesetup.exe***

![Alt text](/screenshots/adk-tool-installation-4.png)

> Check after finished installation

![Alt text](/screenshots/ADK-installation-result.png)

## How to enscapsulate windows PE (Preinstall Environment)

Now let's try to pack bootable environment

Make sure you open **CMD** with **Administrator privileges**


> Change directory to Windows Preinstallation Environment
```cmd
cd "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment"
```
> Make a copy of amd64 folder to C:\winpe
```cmd
.\copype.cmd .\amd64 C:\winpe
```
> mount Image to target folder
```cmd
dism /Mount-Image /ImageFile:C:\winpe\media\sources\boot.wim /Index:1 /MountDir:C:\winpe\mount
```
```cmd
notepad C:\winpe\mount\Windows\System32\startnet.cmd
```


> Add the Samba directory to startnet.cmd and save it

```cmd
rem net use z: \\10.99.1.25\install\win-10 /user:<username> <yourpassword>
net use z: \\10.99.1.25\install\win-10

rem start installation
z:\setup.exe /unattend:\\10.99.1.25\install\autoinstall_conf\win-10.xml 
```
> Umount C:\winpe\mount

```cmd
rem Make sure all opened files are closed
dism /Unmount-Image /MountDir:C:\winpe\mount /Commit
```
> Make ISO file
```cmd
rem Go to Windows Preinstallation Environment
cd "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment"
MakeWinPEMedia.cmd /ISO /f C:\winpe C:\win-10-pe.iso
```
> Then copy it to tftp folder, default will be "/var/lib/tftpboot/bootloader/win-10"

## How to sysprep

### Config unattend file with Windows Image Manager 

![Alt text](/screenshots/how-to-sysprep-windows-10.png) 

![Alt text](/screenshots/sysprep-step-by-step2.png) 

![Alt text](/screenshots/sysprep-step-by-step.png) 


### Config Unattend file


> Use this as an example [Windows 10 Autounattend.xml](/ks/win-10.xml) 
>
> Also you can Check this Microsoft Documentation [https://learn.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/](https://learn.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/)

---
**Pass 1**
```shell
# Windows PE
Microsoft-Windows-International-Core-WinPE
InputLocale: en-US;
SystemLocale: en-US
UILanguage: en-US
UserLocale: en-US

# DiskConfiguration
Microsoft-Windows-Setup -> DiskConfiguration -> Disk
Action = AddListItem
DiskID = 0
WillWipeDisk = true

```

![Alt text](/screenshots/Unattend-pass1-1.png)
```shell

# Add Partation
Right-Click -> Disk[DiskID="0"] -> Add New

Microsoft-Windows-Setup -> DiskConfiguration -> Disk -> Disk[DiskID="0"] -> CreatePartitions
Extend = true
Order = 1
Type = Primary

Microsoft-Windows-Setup -> DiskConfiguration -> Disk -> Disk[DiskID="0"] -> ModifyPartition
Extend = false
Format = NTFS
Lable = Windows 10
Letter = C
Order = 1 
Partation = 1
```
![Alt text](/screenshots/Unattend-pass1-2.png)
![Alt text](/screenshots/Unattend-pass1-3.png)
```shell
# Image install paration
Microsoft-Windows-Setup -> ImageInstall -> OSImage 
InstallToAvaliablePartition = false
WillShowUI = OnError
‵‵
Microsoft-Windows-Setup -> ImageInstall -> OSImage -> InstallTo
DiskID = 0
Partition = 1 
```
![Alt text](/screenshots/Unattend-pass1-4.png)
![Alt text](/screenshots/Unattend-pass1-5.png)

For KMS Client Key you can take a look [https://learn.microsoft.com/en-us/windows-server/get-started/kms-client-activation-keys](https://learn.microsoft.com/en-us/windows-server/get-started/kms-client-activation-keys)

```shell
# The Windows 10 Product key:
Microsoft-Windows-Setup -> UserData -> ProductKey -> Key = {specify your MAK or GVLK key}

# automatically accept user agreement:
Microsoft-Windows-Setup -> UserData  
AccepptEula = True
FullName = Cheertech
Organization = Cheertech
```
![Alt text](/screenshots/Unattend-pass1-6.png)

---

**Pass 4**


```shell
# Only if you need computer to Join Active Directory
Microsoft-Windows-UnattendedJoin -> Identification -> Credentials 
```
![Alt text](/screenshots/Unattend-pass4-6.png)

![Alt text](/screenshots/Unattend-pass4-1.png)
```shell
# To Enable Remote Desktop Connection
Windows-TerminalServices-LocalSessionManager -> fDenyTSConnections = false

Windows-TerminalServices-WinStationExtensions -> 
SecurityLayer = 2 
UserAuthentication = 0 
```
![Alt text](/screenshots/Unattend-pass4-2.png)
![Alt text](/screenshots/Unattend-pass4-3.png)
```shell 
# Allow Firewall Rules
Networking-MPSSVC-Svc -> FirewallGroups
DomainProfile_EnableFirewall = False
PrivateProfile_EnableFirewall = False
PublicProfile_EnableFirewall = False

Networking-MPSSVC-Svc -> FirewallGroups -> (Right-Click) add new -> FirewallGroup
Active = true
Group = Remote Desktop
Key = RemoteDesktop
Profile = All
```
![Alt text](/screenshots/Unattend-pass4-4.png)
![Alt text](/screenshots/Unattend-pass4-5.png)
---
**Pass 7**

```shell
# AutoLogn for First time
Microsoft-Windows-Shell-Setup –> AutoLogon -> 
Enabled = True
LogonCount = 1
Username = itadmin
```
![Alt text](/screenshots/Unattend-pass7-2.png)

```shell
# For Windows Keyboard and language setup 
Windows-International-Core ->
InputLocale = zh-TW  # Keyboard
SystemLocale = zh-TW 
UILanguage = zh-TW # Windows System Language 
UILanguageFallback = zh-TW # Fallback if Fail to setup windows language
UserLocale = zh-TW
```
![Alt text](/screenshots/Unattend-pass7-3.png)
```shell
# Skip Microsoft account creation screen (MSA):
Microsoft-Windows-Shell-Setup –> OOBE -> 
HideEULAPage = True
HideLocalAccountScreen = True
HideOEMRegisterationScreen = True
HideOnlineAccountScreens = True
HideWirelessSetupInOOBE = True

# Do not ask 3 security questions for your local account:
Microsoft-Windows-Shell-Setup –> OOBE -> ProtectYourPC= 1

# Create a local administrator account and set a password for it:
Microsoft-Windows-Shell-Setup –> UserAccounts –> LocalAccounts -> Insert New Local Account
Name: itadmin
Group: Administrators
Password: your password 
```

![Alt text](/screenshots/Unattend-pass7-1.png)

###  Run Sysprep

#### **Why sysprep**
---

Benefits and Disadvantages of Using Sysprep
Syprep’s benefits:
-  Customized Windows 10/11 reference image allows you to quickly deploy a ready-to-work environment on a user’s computer. You do not need to install drivers, programs, or security updates. Also, no need to configure custom Windows settings on each computer;
- It is possible to deploy the Windows image using the answer file (unattended.xml). It allows you to pre-configure all the setup steps and perform Windows installation completely automatically;
- You can extract the image, make changes to it, and update it at any time using the deployment tool.

Disadvantages of Sysprep:

- The size of the Windows reference image can be significantly larger than the clean Windows 10 or 11 installation ISO image;
- You will need to periodically update the versions of programs and drivers injected into the reference image, and install the latest security updates;
- You cannot use the Sysprep tool on domain-joined computers. Sysprep will remove the computer from the AD domain;
- Sysprep can be run up to 1001 times on a single Windows image. Once this limit is reached, you should re-create your Windows image from scratch.
---

#### Before Sysprep

> `Note` Background updates to Microsoft Store apps can break the SysPrep process on modern Windows 10/11 builds. To avoid this, you need to disable automatic updating of Store apps.

- Unplug the Internet connection (Ethernet) or disable your Wi-Fi adapter on your computer;
- Run the Local Group Policy Editor (gpedit.msc) and go to Computer Configuration > Administrative Templates > Windows Components > Store;
- Enable the policy Automatic Download and Install of updates

![Alt text](/screenshots/sysprep-windows-10.png)

Then configure the ImageState registry parameter:

```
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\State" /v ImageState /t REG_SZ /d IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE /f
```
And make changes to the file C:\Windows\Setup\State\State.ini

```
[State]
ImageState=IMAGE_STATE_SPECIALIZE_RESEAL_TO_OOBE
```
This will prevent Sysprep from failing when processing Microsoft Store apps.

![Alt text](/screenshots/a-screenshot-of-a-computer-description-automatica.png)

> - /audit — boots Windows into audit mode. In this mode, you can install additional apps and drivers;
> - /generalize — preparing Windows for image capture. All identifiers, logs, Event Viewer logs, and restore points are removed;
> - /oobe — restarts the Windows in the Welcome screen mode. The Windows Welcome screen allows users to configure Windows operating system, create new accounts, rename the computer, and perform other tasks;
> - /unattend:answer_file_name — allows you to apply the settings from the answer file to Windows during an unattended installation.


#### Step 1. Install OEM Information and Logo (Optional)
---
You can set your company branding info in the Computer Properties windows. In this example, we will set the OEMLogo, Company name, tech support website, and working hours. You can set these through the registry. Create a text file oem.reg, and copy the following code into it:

> `[Note]` You can also add it on unattend answer file  
```
Windows Registry Editor Version 5.00
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation]
“Logo”=”C:\\WINDOWS\\oem\\OEMCheertechlogo.bmp”
“Manufacturer”=”Cheertech, LTM”
“Model”=”Windows 10 Pro 21H1”
“SupportHours”=”9am to 6pm ET M-F”
“SupportURL”=”https://cheertech.com”
```

#### Step 2: Install the Drivers and Apps
---
You can install programs manually, or using the built-in WinGet package manager. Use the WinGet package manager to install the software that you need. (about 5000 programs available in WinGet repo).

> `[Note]` ***Winget only avaliable on windows 22H2 or above***

```
winget install --id=7zip.7zip -e && winget install --id=Google.Chrome -e && winget install --id=Adobe.Acrobat.Reader.32-bit
```
![Alt text](/screenshots/windows-10-sysprep-winget.gif)

You can also install drivers for all the computers and laptop models that you want to use this reference Windows image on. Download and extract the driver packages to a specific directory. Then search for all *.inf files, and inject all the drivers from the source folder into the Windows image with the PowerShell command:

```
Get-ChildItem "C:\Drivers\" -Recurse -Filter "*.inf" |
ForEach-Object {PNPUtil.exe /add-driver $_.FullName /install}
```
---

#### Step 3: Disable Telemetry and Data Collection in Windows 10
---

Windows 10 and 11 collect information about how people use computers. Examples of handwriting and voice samples, location information, error reports, calendar contents – all of this can be sent to Microsoft servers.

If you do not want the OS sending data to Microsoft’s telemetry servers, you can disable the Telemetry and Data Collection services. Run the following commands:


```
sc delete DiagTrack

sc delete dmwappushservice

echo ““ > C:\ProgramData\Microsoft\Diagnosis\ETLLogs\AutoLogger\AutoLogger-DiagTrack-Listener.etl

REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f
```

Also, you can disable tracking in Windows 10 and 11 using the [DisableWinTracking](https://github.com/10se1ucgo/DisableWinTracking) tool from GitHub.

---

#### Step 4: Install Windows Security Update in Audit Mode

Windows will not allow you to install updates in audit mode by using the Windows Update section of the Settings panel. The Windows Update checks if the system has completed the OOBE phase. If not, the update won’t be installed.

You can install the security updates from the command prompt using the [PSWindowsUpdate](https://www.powershellgallery.com/packages/PSWindowsUpdate/2.2.0.3) Module from PowerShell Gallery. Install the PSWindowsUpdate module on Windows using the command:

```
Install-Module -Name PSWindowsUpdate
```

#### Step 5: Uninstall Built-in Microsoft Store Apps
---

```shell
# Music app
Get-AppxPackage *ZuneMusic* | Remove-AppxPackage

# Movies and TV
Get-AppxPackage *ZuneVideo* | Remove-AppxPackage

# MS Office
Get-AppxPackage *MicrosoftOfficeHub* | Remove-AppxPackage

# People app
Get-AppxPackage *People* | Remove-AppxPackage

# Maps
Get-AppxPackage *WindowsMaps* | Remove-AppxPackage

# Help and tips
Get-AppxPackage *GetHelp* | Remove-AppxPackage

# Voice Recorder
Get-AppxPackage *WindowsSoundRecorder* | Remove-AppxPackage

# Teams/Chat
Get-AppxPackage *Teams* | Remove-AppxPackage

# Microsoft Edge
Get-AppxPackage *MicrosoftEdge* | Remove-AppxPackage

# OneDrive
Get-AppxPackage *OneDriveSync* | Remove-AppxPackage

# Skype
Get-AppxPackage *SkypeApp* | Remove-AppxPackage

# Xbox Console Companion
Get-AppxPackage *GamingApp* | Remove-AppxPackage
```

#### Setup Networks & Clean Caches 
---

- Setup Network as DHCP
```
$IPType = "IPv4"
$adapter = Get-NetAdapter | ? {$_.Status -eq "up"}
$interface = $adapter | Get-NetIPInterface -AddressFamily $IPType
If ($interface.Dhcp -eq "Disabled") {
If (($interface | Get-NetIPConfiguration).Ipv4DefaultGateway) {
$interface | Remove-NetRoute -Confirm:$false
}
$interface | Set-NetIPInterface -DHCP Enabled
$interface | Set-DnsClientServerAddress -ResetServerAddresses
}
```

- Use the Disk Clean-up tool (cleanmgr.exe) to remove junk and unnecessary files from your computer’s hard disk;

![Alt text](/screenshots/system-preparation-tool-3-14.png)

- Empty the Recycle Bin;
- Remove temporary files and folders (%LocalAppData%\temp, C:\Windows\Temp, etc.);
- Before running Sysprep, delete all user profiles, except for the Administrator and Default profiles.
- Clean up the Web Cache files in the Administrator and Default profiles
```
rd /s /q "C:\Users\Administrator\AppData\Local\Microsoft\Windows\WebCache"
rd /s /q "C:\Users\Administrator\AppData\Local\Microsoft\Windows\INetCache"
del /f /q /a:sh "C:\Users\Administrator\AppData\Local\Microsoft\Windows\WebCacheLock.dat"
rd /s /q "C:\Users\Default\AppData\Local\Microsoft\Windows\WebCache"
rd /s /q "C:\Users\Default\AppData\Local\Microsoft\Windows\INetCache"
del /f /q /a:sh "C:\Users\Default\AppData\Local\Microsoft\Windows\WebCacheLock.dat"
```

> `[Note]` Run this command only if you want to do the update
Run the following commands to download and install all available Windows updates:

```
PowerShell -ExecutionPolicy RemoteSigned -Command Import-Module PSWindowsUpdate;
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot
```

#### Finalize
---

> `Note`open cmd with administrator privileges and type the following command
```cmd
rem Make sure you put your autounattend file under C:\
C:\Windows\System32\Sysprep\sysprep.exe /oobe /generalize /shutdown /unattend:C:\win-10.xml
```
![Alt text](/screenshots/sysprep-generalize-768x141.png)

###  Capture Image (Using DISM after Generalize)
---

1. Boot up Image to installation Page
2. Press Shift + F10 on the first setup screen.
3. Type Diskpart command. Use the list vol command to identify the drive letters. In our example, the installed Windows image is located on drive C

![Alt text](/screenshots/sysprep-image-768x313.png)
```
dism /capture-image /imagefile:\\10.99.1.25\install\sysprep\\win-10-sysprep.wim /capturedir:C: /name:"Win 10 Pro"
```
![Alt text](/screenshots/windows-11-sysprep-generalize-768x210.png)

---

###  Convert Wim To ISO
---
```
oscdimg.exe -m -o -u2 -udfver102 -bootdata:2#p0,e,bd:(file_path)\boot\etfsboot.com#pEF,e,bd:\(file_path)\efi\microsoft\boot\efisys.bin C:\(file_path) C:\Windows-10-Pro-x64.iso
```
---


### Add Windows Update packages

#### Step 1
---
Download update from [Microsoft Update Catalog](https://www.catalog.update.microsoft.com/Home.aspx)

---
![Alt Text](/screenshots/windows-update-1.png)
```
cd C:\temp

expand -f:* windows10.0-kb5015020-x64_5a735e4c21ca90801b3e0b019ac210147a978c52.msu C:\
```
![Alt Text](/screenshots/extract-msu-to-cab.png)

#### Step 2

Download Dsim++ from [https://github.com/Chuyu-Team/Dism-Multi-language/releases](https://github.com/Chuyu-Team/Dism-Multi-language/releases) 

#### Step 3 
Mount Image to mount folder

```
dism /Mount-Image /ImageFile:C:\win-10\sources\install.wim /Index:1 /MountDir:C:\mount
```

#### Step 4

![Alt Text](/screenshots/DISM++.png)

#### Step 5 

Umount Image

```
dism /Unmount-Image /MountDir:C:\mount /Commit
```
---

### Remove Images from wim file

> Get Image info
```
Dism /Get-ImageInfo /imagefile:c:\win-10\sources\install.wim
```

> Strip from Image from wim
```
Remove-WindowsImage -ImagePath "c:\win-10\sources\install.wim" -Index 1 -CheckIntegrity
```

## Windows Troubleshooting

### ADK Toolkit (Windows System Image Manager)

`Note` If you try to open the install.wim file of your Windows 10 build using WSIM from an older version of the ADK, you may receive an error message:
```
Windows SIM was unable to generate a catalog.
```
![Alt text](/screenshots/sysprep-win10-error.png)

> In order to fix this error, you need to install the latest ADK and WSIM available for your Windows build.


---

### Copype
```
ERROR: The following processor architecture was not found: .\amd64\.
```
Try to add this two lines to copype.cmd on : line 16

```
set WINPE_ARCH=%1
set WinPERoot=C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment
set SOURCE=%WinPERoot%\%WINPE_ARCH%
set OSCDImgRoot=C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg
set FWFILESROOT=%OSCDImgRoot%\..\..\%WINPE_ARCH%\Oscdimg
set DEST=%~2
```

---

### MakeWinPEMedia.cmd 

![Alt text](/screenshots/oscdimg-troubleshoot.png)
```cmd
'Oscdimg' Not Recognized as an Internal or External Command
``````

Add this one 
```cmd
C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg
```
![Alt text](/screenshots/oscdimg-solution.png)

---

### Sysprep

> `Note` In some cases, SysPrep returns the error: unable to validate your Windows installation. The cause of the error is listed in the %WINDIR%\System32\Sysprep\Panther\setupact file.

![Alt text](/screenshots/windows-sysprep-error.png)