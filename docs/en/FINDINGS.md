# Findings

This document walks through the work, the real problems encountered, and the conclusions drawn for each visibility component.

## 1. Network Traffic Analysis

**Tool:** Wireshark (capture filters: `tcp`, `udp`) · **Source:** `python3 -m http.server` on Kali (10.10.10.101) · **Test client:** Windows client (10.10.10.100), via `Invoke-WebRequest` and `nslookup`

### First attempt — failure (troubleshooting)

On the first connection attempt:
- **TCP:** 5 SYN packets were each answered with `RST,ACK` from Kali.
- **DNS/UDP:** `nslookup <name> 10.10.10.101` queries returned ICMP **Port Unreachable**.

**Interpretation:** A `RST,ACK` in response to a SYN is not silence (a firewall silently dropping the packet) — it means the target **actively refused** the connection, which indicates no service is listening on that port. The same logic applies to ICMP Port Unreachable on the UDP side.

**Root cause:** `python3 -m http.server 8080` was not bound to the correct interface/address.

**Fix:**
```bash
python3 -m http.server -b 10.10.10.101 8080
```

### Second attempt — success

After fixing the bind address:
- Full 3-way handshake: `SYN` → `SYN,ACK` (seq +1) → `ACK`
- Client sent a `GET /` request (~158 bytes including headers)
- Kali responded with `200 OK` (~1722 bytes) — split into **2 TCP segments** due to the MSS limit (~1460 bytes), each acknowledged separately by the client
- Connection closed cleanly via `FIN,ACK`

### DNS query — additional observation

`nslookup` first issued a **reverse (PTR) query** (`101.10.10.10.in-addr.arpa`) to resolve the name of the DNS server it was pointed at (10.10.10.101), before sending the actual query — this is default `nslookup` behavior, not something we asked for. Since no DNS service was running on Kali, the queries went unanswered (ICMP Port Unreachable), which was still enough to analyze the packet structure (Transaction ID, Query Name).

## 2. Windows Event Log Analysis

**Environment:** Windows Server (10.10.10.10)

### Scenario

1. A user was created with `New-LocalUser` → **Event 4720**
2. A failed authentication attempt was triggered → **Event 4625**
3. The user was removed with `Remove-LocalUser` → **Event 4726**

### Troubleshooting the 4625 event

`runas /user:.\<user> cmd` with a wrong password failed with **"Unable to acquire user password"** — an error at the **Secondary Logon service** level, occurring before authentication was even attempted, so no event was logged at all.

**Fix:** A real network authentication attempt was used instead:
```powershell
net use \\localhost\c$ /user:.\<user> <wrong_password>
```
This produced a failed **Logon Type 3** (Network) authentication attempt and generated Event 4625.

### 4625 field analysis

| Field | Value |
|---|---|
| Logon Type | 3 (Network) |
| TargetUserName | NewUser |
| Failure Reason | `%%2313` — "Unknown user name or bad password" |
| Source Address | `::1` (IPv6 loopback), port 65425 |

**Note:** Windows deliberately keeps this message vague — it does not reveal in the visible text whether the username or the password was wrong (to make username enumeration harder). Internally, a more specific hex sub-status code (`0xC0000064` / `0xC000006A`) does distinguish between the two, but the surface-level message is intentionally generalized.

### Audit Policy verification

```powershell
auditpol /get /category:"Logon/Logoff"
```
Confirmed that **Success and Failure** auditing was enabled for the Logon subcategory — ruling out an audit-policy gap as the reason events weren't showing up.

### 4726 (deletion)

| Field | Value |
|---|---|
| SubjectUserName | Windows (the account that performed the deletion) |
| TargetUserName | NewUser (the deleted account) |

## 3. Linux Log Analysis

**Environment:** Kali (10.10.10.101), SSH service enabled

`/var/log/auth.log` **did not exist**. Reason: flat-file syslog records (like `auth.log`) only get created if a syslog daemon such as `rsyslog` is installed; it is not installed on Kali by default, so the system writes only to **journald** (a structured/binary format).

**Fix:**
```bash
sudo journalctl -u ssh -e
```

### Observed log

A failed SSH connection attempt from the Windows client (10.10.10.100), using a nonexistent username:

```
Invalid user anan from 10.10.10.100 port 65428
pam_unix(sshd:auth): check pass; user unknown
pam_unix(sshd:auth): authentication failure; ... ruser= rhost=10.10.10.100
Failed password for invalid user anan from 10.10.10.100 port 65428 ssh2
... (3 retries)
Connection reset by invalid user anan 10.10.10.100 port 65428 [preauth]
PAM 2 more authentication failures; ...
```

### Windows vs Linux log verbosity comparison

Unlike Windows, Linux/PAM states explicitly that the username **does not exist** ("Invalid user", "user unknown"). This is not an exposed channel to an attacker — this log is only visible to an analyst on the server; a remote attacker cannot read this file. The actual username-enumeration risk exists at the **protocol level**; modern OpenSSH already mitigates this by deliberately normalizing response timing for valid vs. invalid usernames.

## 4. PowerShell Collection

**Environment:** Windows client (10.10.10.100)

A single script was written to collect the following into `system-report.txt`:

- Running processes (`Get-Process`)
- Active network connections (`Get-NetTCPConnection`)
- Local user list (`Get-LocalUser`)
- Basic system information (`Get-ComputerInfo`)

### Troubleshooting

Running the script failed with **"Running scripts is disabled on this system"** — the default Execution Policy (`Restricted`) blocks script execution entirely.

**Fix:**
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```
`RemoteSigned` only requires downloaded (remote) scripts to be signed; it does not restrict locally written scripts — a narrower, safer choice than `Unrestricted`.

**Note:** Execution Policy is not a real security boundary — it can be trivially bypassed with `powershell -ExecutionPolicy Bypass`. Detection should therefore be based on process behavior, not on this setting.

## Lessons Learned

- **An event being generated does not mean it's visible.** On Windows this depends on Audit Policy (the Logon/Logoff category); on Linux it depends on whether a syslog daemon (rsyslog) is installed — neither is guaranteed by default.
- **Execution Policy is a safety net, not a security control** — `RemoteSigned` and `Unrestricted` are genuinely different, but neither stops a determined attacker.
- **Active refusal (RST / Port Unreachable) and silent drop are different signals** — one says "port closed," the other says "filtered somewhere"; being able to tell them apart directly saves troubleshooting time.
- **Log verbosity is not a vulnerability.** However detailed a server-side log is, it's only exposed to whoever can read that log (the analyst); the real risk is what the protocol itself reveals to a remote attacker.
