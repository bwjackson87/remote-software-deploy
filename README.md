# Remote Software Deployment via WMI

A PowerShell script for pushing software installations to remote Windows hosts using WMI (`Win32_Process`), without requiring PowerShell Remoting (WinRM) to be enabled on the target machine.

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue?logo=powershell) ![Platform](https://img.shields.io/badge/Platform-Windows-lightgrey?logo=windows) ![License](https://img.shields.io/badge/License-MIT-green)

## Use Case

In managed enterprise environments, approved software packages are often staged on a central file share. This script lets an administrator trigger a silent installation on any reachable Windows host using only WMI/DCOM — a protocol that is almost always permitted on internal networks even when WinRM is not configured.

## Requirements

| Requirement | Detail |
|-------------|--------|
| PowerShell | 5.1 or later |
| Network | DCOM access to target (TCP 135 + dynamic RPC port range) |
| Permissions | Local administrator rights on the target host |
| Share access | Target machine must be able to read the UNC installer path |

## Usage

```powershell
.\Deploy-Software.ps1 -ComputerName "WORKSTATION01" `
    -InstallerPath "\\fileserver.corp.local\Software\GoogleChrome\ChromeSetup.exe"
```

### Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `-ComputerName` | Yes | NetBIOS name or FQDN of the remote host |
| `-InstallerPath` | Yes | Full UNC path to the installer executable |

### Example Output

```
Connecting to WORKSTATION01 via WMI...
SUCCESS — process started on WORKSTATION01 (PID 4832)
```

## How It Works

1. Instantiates a `Win32_Process` WMI object bound to the remote host
2. Calls `Create()` to spawn `cmd.exe /c "<installer>"` on that host
3. Checks the integer return code and maps it to a human-readable status
4. Reports the process ID on success, or a descriptive error on failure

WMI `Win32_Process.Create()` return codes handled:

| Code | Meaning |
|------|---------|
| 0 | Success |
| 2 | Access Denied |
| 3 | Insufficient Privilege |
| 8 | Unknown Failure |
| 9 | Path Not Found |
| 21 | Invalid Parameter |

## Security Considerations

- The installer UNC path is quoted when passed to `cmd.exe` to prevent argument injection from paths containing spaces
- This script requires **local administrator credentials** on the target; scope access carefully
- Prefer a dedicated service account with least-privilege admin rights over using domain admin credentials for bulk deployments

## License

MIT — see [LICENSE](LICENSE) for details.
