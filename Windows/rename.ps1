# Define log file path
$logFilePath = 'C:\rename.log'
$restartFlagPath = 'C:\RestartFlag.txt'

# Function to log messages
function Log-Message {
    param (
        [string]$message
    )

    # Get current date and time
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # Format log entry
    $logEntry = "$timestamp - $message"

    # Append log entry to the log file
    Add-Content -Path $logFilePath -Value $logEntry
}

# Hardcoded domain credentials
$domainUsername = 'ark88\administrator'
$securePassword = ConvertTo-SecureString -String 'mxywZkt8wSkV' -AsPlainText -Force
$domainCredential = New-Object System.Management.Automation.PSCredential -ArgumentList @($domainUsername, $securePassword)

# The script is running for the first time
Log-Message "Initial run of the script."

# Map network drive
try {
    # Map network drive with provided credentials
    net use Y: \\10.99.1.25\install\software_packages /user:root P@ssw0rd
    Log-Message "Mapped network drive successfully."
} catch {
    $errorMessage = "Failed to map network drive: $_"
    Log-Message $errorMessage
    # Handle the error as needed
    exit 1
}

# Get serial number
$serialNumber = (Get-CimInstance Win32_BIOS).SerialNumber

# Read assettag.txt and find matching line
try {
    $assetData = Get-Content -Path "\\10.99.1.25\install\autoinstall_conf\assettag.txt" | Where-Object { $_ -match $serialNumber }
    Log-Message "Read assettag.txt successfully."

    try{
        net use Y: /d /y 
        Log-Message "Umount Mapped Drive Successfully"
    } catch {
        $errorMessage = "Failed to umount Y:"
        Log-Message "Failed to Umount Mapped Drive "
    }
} catch {
    $errorMessage = "Failed to read assettag.txt: $_"
    Log-Message $errorMessage
    # Handle the error as needed
    exit 1
}

# If matching data found
if ($assetData) {
    Log-Message "Asset Tag Match founded"
    try {
        # Extract information
        $assetInfo = $assetData -split '\t'
        
        # Rename computer
        Rename-Computer -NewName $assetInfo[0] -Force -DomainCredential $domainCredential 
        Log-Message "Renamed computer successfully to $($assetInfo[0]). "

        # Install Rohos Key
        try{
            Copy-Item -Path \\10.99.1.25\install\software_packages\rohos_welcome.exe -Destination C:\
            Log-Message "Copy Rohos Client to C Drive"
            C:\rohos_welcome.exe /VERYSILENT /regkey=$assetInfo[3] /disableui=0 /NoTextLabels=10 /DisableCredUI=1
            Log-Message "Deploy Rohos Key $($assetInfo[3]) Succcessfully To $($assetInfo[0])"
        }
        catch {
            Log-Message "Failed To Deploy $($assetInfo[3]) To $($assetInfo[0])"
        }

        # Add Vlan 
        Add-IntelNetVLAN -ParentName $((Get-NetAdapter -Name * -Physical).InterfaceDescription) -VLANID $assetInfo[2]
        Log-Message "Vlan Changed To $($assetInfo[2])."

        # Restart computer
        Restart-Computer -Force

        # Check if the computer restarted successfully
        if (-not (Test-Connection -ComputerName localhost -Count 1 -Quiet)) {
            Log-Message "Computer did not restart successfully."
            # Restart computer
            Restart-Computer -Force
            exit 1
        }

        # Create a flag file to indicate the script is running after a restart
        New-Item -ItemType File -Path $restartFlagPath -Force

    } catch {
        $errorMessage = "An error occurred during configuration: $_"
        Log-Message $errorMessage
        # Handle the error as needed
        exit 1
    }
} else {
    Log-Message "Asset Tag Match not founded"
}
