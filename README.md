---
> **Security & Sanitization Notice:** This repository contains sanitized, lab-safe code and documentation. It does not include proprietary, classified, sensitive, or employer-owned data. Hostnames, domains, usernames, IP addresses, and operational details are fictionalized or generalized. See [SECURITY_NOTICE.md](SECURITY_NOTICE.md) for full details.
---

# Remote Software Deployment via WMI

## Overview
A PowerShell script for triggering silent software installations on remote Windows hosts using WMI (`Win32_Process.Create`), without requiring PowerShell Remoting (WinRM) to be enabled on the target. The installer runs under the machine's SYSTEM context from a UNC path on a central file share.

## Problem It Solves
Enterprise environments frequently have WinRM disabled by default or blocked by network policy — but WMI/DCOM is almost always open on internal networks. When an approved package needs to be pushed to a machine that is not reachable via `Invoke-Command` or `Enter-PSSession`, this script provides a reliable delivery path using only the protocols that are already available. It bridges the gap between fully managed SCCM deployments and ad-hoc, one-off installation needs.

## Key Features
- Deploys any installer (EXE or MSI) to a remote host via WMI — no WinRM required
- Reads the installer from a UNC share, so no file transfer to the target is necessary
- Maps all `Win32_Process.Create` return codes to human-readable status messages
- Reports the spawned Process ID on success for tracking
- Quoted installer paths prevent argument injection from paths containing spaces
- Minimal dependencies — PowerShell 5.1+ and DCOM access only

## Technologies Used
- PowerShell 5.1+
- WMI (`Win32_Process`) via DCOM (TCP 135 + dynamic RPC)
- UNC file share for installer staging

## Example Use Case
A user's workstation is missing a required productivity application. The machine is on a remote site VLAN where WinRM is blocked by the local firewall, and the SCCM deployment for this package is targeting the wrong collection. Rather than opening a ticket with the network team or driving to the site, an administrator runs this script from their workstation — the application installs silently in under a minute without touching the target machine's firewall rules.

## How to Run

```powershell
.\Deploy-Software.ps1 -ComputerName "WORKSTATION01" `
    -InstallerPath "\fileserver.corp.local\Software\7zip\7z2301-x64.exe"
```

| Parameter | Required | Description |
|---|---|---|
| `-ComputerName` | Yes | NetBIOS name or FQDN of the remote host |
| `-InstallerPath` | Yes | Full UNC path to the installer (EXE or MSI) |

## Example Output

```
Connecting to WORKSTATION01 via WMI...
SUCCESS — process started on WORKSTATION01 (PID 4832)
```

**WMI return codes handled:**

| Code | Meaning |
|---|---|
| 0 | Success |
| 2 | Access Denied |
| 3 | Insufficient Privilege |
| 8 | Unknown Failure |
| 9 | Path Not Found |
| 21 | Invalid Parameter |

## Security Notes
- Requires **local administrator credentials** on the target host — use a least-privilege service account scoped to the target OUs, not domain admin
- The target machine's computer account must have read access to the UNC installer share
- Installer paths containing spaces are quoted when passed to `cmd.exe` to prevent argument injection
- WMI/DCOM must be permitted on the target (TCP 135 + dynamic RPC range 49152–65535) — this is standard on internal networks but should be verified before assuming access
- Authorized use only — run only against systems and software you are authorized to manage

## Lessons Learned
- `Win32_Process.Create` spawns the process under SYSTEM, not the calling user — the installer UNC path must be accessible by the machine account, not just the admin account running the script
- Mapping integer return codes to readable strings immediately at the call site prevents the silent "it returned 3" confusion that makes WMI failures hard to diagnose after the fact
- This script intentionally does not wait for the installation to complete — `Create()` is fire-and-forget; verifying success requires a follow-up check (registry query or `Get-WmiObject Win32_Product`) after an appropriate delay
- Pairs naturally with [force-uninstall-sccm](https://github.com/bwjackson87/force-uninstall-sccm) for a full remove-then-redeploy workflow
