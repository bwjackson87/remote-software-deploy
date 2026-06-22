<#
.SYNOPSIS
    Remotely installs software on a target Windows host using WMI.

.DESCRIPTION
    Uses Win32_Process over WMI to launch an installer that lives on a UNC
    share, without requiring PowerShell Remoting (WinRM) to be enabled on
    the target. Useful for push-deploying approved software packages across
    a managed Windows environment.

.PARAMETER ComputerName
    NetBIOS name or FQDN of the remote host.

.PARAMETER InstallerPath
    Full UNC path to the installer executable. The remote host must have
    read access to this share.

.EXAMPLE
    .\Deploy-Software.ps1 -ComputerName "WORKSTATION01" `
        -InstallerPath "\\fileserver.corp.local\Software\GoogleChrome\ChromeSetup.exe"

.NOTES
    Requirements:
      - WMI (DCOM) access to the remote host (TCP 135 + dynamic RPC range)
      - The account running this script must have local admin rights on the target
      - The target machine must have network access to the UNC share
#>

param (
    [Parameter(Mandatory)]
    [string]$ComputerName,

    [Parameter(Mandatory)]
    [string]$InstallerPath
)

# Win32_Process return codes
$ReturnCodes = @{
    0  = "Success"
    2  = "Access Denied"
    3  = "Insufficient Privilege"
    8  = "Unknown Failure"
    9  = "Path Not Found"
    21 = "Invalid Parameter"
}

Write-Host "Connecting to $ComputerName via WMI..." -ForegroundColor Cyan

try {
    $wmi = [WMIClass]"\\$ComputerName\root\cimv2:Win32_Process"
    $result = $wmi.Create("cmd.exe /c `"$InstallerPath`"")

    $code = $result.ReturnValue
    $meaning = if ($ReturnCodes.ContainsKey($code)) { $ReturnCodes[$code] } else { "Unknown ($code)" }

    if ($code -eq 0) {
        Write-Host "SUCCESS — process started on $ComputerName (PID $($result.ProcessId))" -ForegroundColor Green
    } else {
        Write-Warning "FAILED on $ComputerName — Return code $code : $meaning"
    }
}
catch {
    Write-Error "Could not connect to $ComputerName : $_"
}
