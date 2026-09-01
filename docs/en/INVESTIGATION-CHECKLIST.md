# Basic Investigation Checklist

An UNDERSTAND → DECIDE → HANDOFF flow, adapted to the telemetry types produced in this project (network capture, Windows event log, PowerShell collection).

## 1. Understand

Make sense of each finding by asking:

- When, on which host, by which user did this happen?
- Did it actually happen, or is it noise (e.g. a misconfigured service)?
- Was it a planned change — is there a corresponding Change Management record?
- Was it an authorized action?

**For network captures:** check source and destination addresses/ports — is there an unusual connection? Are there anomalies in the packets (unexpected RST, port unreachable, unusual size)?

**For event logs:** is the created/deleted/accessed resource recorded in Change Management, and by whom?

Enrich if needed (TI lookups, checking related log sources).

## 2. Decide

Compare the gathered evidence: is this genuinely an authorized action, or is it suspicious?

Verdict: **True Positive / False Positive / Benign True Positive**

## 3. Handoff

- **False Positive** → close it; if warranted, send a tuning suggestion to Detection Engineering.
- **True Positive** → apply the defined containment step from the playbook if one exists; otherwise escalate directly to L2 with the findings.
