# Normal vs Suspicious Activity Comparison

| Telemetry | Normal | Suspicious | Why I'd flag it |
|---|---|---|---|
| **Network** | A closed port only receives traffic in response to connections we initiated ourselves. | An unexpected, unsolicited request arriving at a closed/unexpected port. | May indicate port scanning from an unexpected source, or an attempt to reach a misconfigured service. |
| **Windows Event** | User creation/deletion goes through Change Management and is announced beforehand. | A user-creation event (4720) with no matching Change Management record. | May indicate an unauthorized or off-the-books account creation — potentially for persistence. |
| **Linux Log** | SSH access is typically key-based; nobody attempts logon with a random username except by typo. | Repeated failed logon attempts with a nonexistent/random username, or repeated bad passwords against a valid user. | Signals an unauthorized access attempt — SSH auth logs (invalid user, failed password) can serve as an IoC. |
