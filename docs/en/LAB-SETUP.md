# Lab Setup Guide

## Environment

- Hypervisor: VMware Workstation Pro
- Network mode: Host-Only, `10.10.10.0/24`, isolated (no internet access)
- Gateway: `10.10.10.1` (host machine)

| Role               | Hostname        | IP           | Subnet          | Gateway     |
|--------------------|-----------------|--------------|-----------------|-------------|
| Gateway (host)     | —               | 10.10.10.1   | 255.255.255.0   | —           |
| DC (Windows Srv)   | WIN-3GTJDFSUSVD | 10.10.10.10  | 255.255.255.0   | 10.10.10.1  |
| Linux (Ubuntu)     | ubuntu          | 10.10.10.20  | 255.255.255.0   | 10.10.10.1  |
| Client (Win 11)    | —               | 10.10.10.100 | 255.255.255.0   | 10.10.10.1  |
| Kali               | kali            | 10.10.10.101 | 255.255.255.0   | 10.10.10.1  |

Ubuntu netplan configuration (`/etc/netplan/*.yaml`):

```yaml
network:
  version: 2
  ethernets:
    ens33:
      addresses:
      - "10.10.10.20/24"
      nameservers:
        addresses:
        - 10.10.10.10
      routes:
      - to: "default"
        via: "10.10.10.1"
```

## Issues Encountered During Setup

### 1. Windows Server 2022 Evaluation — licensing error

A license validation error occurred during setup.

**Fix:** Disable the Floppy Disk device in VMware settings. The virtual floppy drive confuses Windows' installation/activation flow.

### 2. VMs could not ping each other

After IP assignment, hosts on the same subnet could not reach one another.

**Root cause:** The Windows VM had an IP address assigned but no Subnet Mask or Default Gateway.

**Fix:**
```powershell
Remove-NetIPAddress -InterfaceIndex 15
New-NetIPAddress -InterfaceIndex 15 -IPAddress 10.10.10.10 -PrefixLength 24 -DefaultGateway 10.10.10.1
```
The interface had to be cleared first — otherwise the same interface ended up holding multiple IP addresses.

### 3. Windows 11 installation failing

**Root cause:** Windows 11 setup requires Secure Boot to be enabled.

**Fix:** Enable Secure Boot in the VM settings.

### 4. No ping response after Windows 11 setup

**Root cause:** Windows Defender Firewall blocks inbound/outbound ICMPv4 requests by default.

**Fix:** Allow ICMPv4 echo request/reply in the firewall rules.
