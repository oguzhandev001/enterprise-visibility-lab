# Enterprise Endpoint and Network Visibility Lab

🇬🇧 English | 🇹🇷 [Türkçe](README.tr.md)

A small-scale Blue Team lab simulating a corporate environment, built to collect and analyze end-to-end **visibility** data from Windows and Linux systems. The goal wasn't just to generate logs and traffic — it was to actually read and interpret every signal produced, and to identify real gaps in visibility (audit policy, logging infrastructure) along the way.

## Lab Topology

Network mode: **Host-Only** (isolated, no internet access), subnet `10.10.10.0/24`.

```
                        10.10.10.0/24
                      VLAN 1 (Host-Only)
                             |
        +-----------+-----------+-----------+
        |           |           |           |
   10.10.10.10  10.10.10.20 10.10.10.100 10.10.10.101
   DC (Win Srv) Ubuntu Srv  Win 11 Client    Kali
```

| Role               | Hostname        | IP           | Gateway     |
|---------------------|-----------------|--------------|-------------|
| Gateway (host)       | —               | 10.10.10.1   | —           |
| DC (Windows Srv)     | WIN-3GTJDFSUSVD | 10.10.10.10  | 10.10.10.1  |
| Linux (Ubuntu)       | ubuntu          | 10.10.10.20  | 10.10.10.1  |
| Client (Win 11)      | —               | 10.10.10.100 | 10.10.10.1  |
| Kali                 | kali            | 10.10.10.101 | 10.10.10.1  |

Full setup details and infrastructure troubleshooting: [`docs/en/LAB-SETUP.md`](docs/en/LAB-SETUP.md)

## Scope

| Component | What was done |
|---|---|
| **Network Traffic Analysis** | TCP handshake, HTTP traffic, and DNS query analysis in Wireshark — both a failed (troubleshooting) and a successful scenario |
| **Windows Event Log Analysis** | Generating and field-level analysis of user creation/deletion and failed logon events (4720/4625/4726) |
| **Linux Log Analysis** | A failed SSH authentication attempt against the SSH service, examined via journald |
| **PowerShell Collection** | An automation script collecting process, network connection, local user, and system information in one pass |
| **Investigation Checklist** | An Understand / Decide / Handoff triage flow adapted to this project's telemetry types |
| **Normal vs Suspicious** | A comparison of normal vs. suspicious behavior for each telemetry type |

Full findings and troubleshooting narrative: [`docs/en/FINDINGS.md`](docs/en/FINDINGS.md)
Investigation checklist: [`docs/en/INVESTIGATION-CHECKLIST.md`](docs/en/INVESTIGATION-CHECKLIST.md)
Normal vs Suspicious comparison: [`docs/en/NORMAL-VS-SUSPICIOUS.md`](docs/en/NORMAL-VS-SUSPICIOUS.md)

## Key Findings

- Observed and correctly distinguished that a closed TCP port responds to a SYN with an **active** `RST,ACK` — a fundamentally different signal from a firewall silently dropping the packet.
- Compared how Windows' failed-logon event (`%%2313`) **deliberately obscures** whether the username or password was wrong, versus Linux/PAM stating "invalid user" explicitly — and recognized this as a log-visibility question, not a vulnerability.
- Experienced firsthand the difference between an event being **generated** and an event being **visible** — via Windows Audit Policy and the Linux rsyslog/journald distinction.

## Tools Used

VMware · Wireshark · Windows Event Viewer · `journalctl` / systemd-journald · PowerShell · OpenSSH

## Evidence

Raw evidence files live in [`evidence/`](evidence/):

| File | Content |
|---|---|
| `network-capture.pcapng` | Wireshark network capture (RST/ACK troubleshooting + successful handshake) |
| `system-report-script.ps1` | The PowerShell collection script itself |
| `system-report.txt` | Full script output (process/connection/user/system info) |
| `ssh_logs.txt` | `journalctl -u ssh` output on Kali — the failed SSH attempt |
