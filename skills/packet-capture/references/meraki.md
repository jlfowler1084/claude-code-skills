# Cisco Meraki — Dashboard Capture + SPAN

Cloud-managed architecture: captures are initiated through the Meraki Dashboard and
delivered as a `.pcap` file for local analysis in Wireshark. No software is installed
on the device being captured; all analysis happens on the analyst's laptop.

---

## 1. Dashboard Packet Capture

Navigate to **Network-wide > Monitor > Packet capture**.

1. **Select the Network device** — choose the MX (security appliance), MS (switch), or
   MR (access point) you want to capture on.
2. **Pick the interface** — the available interfaces reflect the selected device type
   (WAN uplink, LAN port, SSID, etc.).
3. **Optional: enter a filter expression** — BPF-style capture filter to narrow the
   capture (e.g. `host <TARGET-IP>`, `port 443`, `tcp`).
4. **Set Output = "Download .pcap file (for Wireshark)"** — this is the mode that
   produces a standard pcap artifact for Wireshark. The alternative "View output below"
   is a browser-rendered summary only.
5. Click **Start capture**.
6. Reproduce the problem, then click **Stop** (or let the capture time out).
7. Download the `.pcap` file and open it in Wireshark on the analyst laptop.

> **MR (wireless access points — current firmware):** The MR uses
> **Network-wide > Monitor > Intelligent Capture** rather than the standard Packet
> Capture page. Navigate there for wireless captures.
> An MR access point can only decrypt traffic on its own BSSID; traffic to/from other APs appears encrypted.

### Dashboard capture timeouts

| Output mode | Empty-capture timeout |
|---|---|
| Download .pcap file (for Wireshark) | **60 seconds** |
| View output below (browser summary) | **20 seconds** |

If no packets match the filter within the timeout window, the capture ends with an
empty result — check the filter expression and network device selection.

---

## 2. Fidelity Caveats

> These caveats are critical. Read before deciding whether Dashboard capture is
> sufficient for your investigation.

### Live-streaming to Wireshark is NOT supported

**Meraki Dashboard does not officially support piping a live capture stream directly
into Wireshark.** The only supported output modes are:
- "View output below" — browser-rendered text summary (no pcap, 20s timeout)
- "Download .pcap file (for Wireshark)" — file download after capture completes

Do not assume a named-pipe or extcap integration will work. Use the download workflow
described in §1, or use SPAN/TAP (§3) for a continuous live feed to Wireshark.

### Dashboard captures are NOT guaranteed to show 100% of packets

Dashboard captures are **not guaranteed to deliver every frame**. Under load or when
cloud-upload bandwidth is constrained, frames can be dropped. If packet-level fidelity
is essential (e.g., diagnosing intermittent drops, verifying exact retransmission
counts, or validating sequence numbers), use **SPAN** or a **physical TAP** instead —
see §3.

### MX cannot see LAN-to-LAN switched traffic

An **MX security appliance only sees traffic that is routed through it** — plus
broadcasts and multicasts on connected segments. It **cannot see east-west traffic
between two clients on the same VLAN** because that traffic is switched at the MS
layer and never reaches the MX.

**For east-west (same-VLAN) captures:** capture at the **MS switch** using a Dashboard
capture on the MS device, a local port mirror (§3.1), or a physical TAP on the
relevant port. Do not attempt to diagnose same-VLAN client-to-client issues using
an MX capture.

---

## 3. SPAN / Port Mirroring (Full-Fidelity Capture to a Laptop)

Use SPAN when you need:
- A continuous live stream into Wireshark
- Wire-rate capture without the cloud-upload limits of Dashboard captures
- East-west (same-VLAN) traffic the MX cannot see

Connect the Wireshark laptop's NIC to the **destination port** of the mirror. The
destination port operates in receive-only mode during mirroring — it will not pass
normal traffic to the laptop. Plan a separate management path (second NIC or
out-of-band) for the Wireshark laptop if you need to manage it during the capture.

### 3.1 MS Local Port Mirror (on-switch SPAN)

**Dashboard path:** Switch > Monitor > Switch ports

1. Select the **source port(s)** you want to mirror.
2. Click **Mirror**.
3. Pick **one destination port** on the same switch or stack.
4. Apply.

**Constraints:**
- Source and destination must be on the **same switch or stack**.
- A **LAG (Link Aggregation Group) can be a source** but **cannot be a destination**.
- An **uplink port cannot be a destination**.
- The destination port has **no normal connectivity** while mirroring is active.

### 3.2 Network-wide Traffic Mirroring (RSPAN / cross-switch)

**Dashboard path:** Switch > Switch settings > Traffic mirroring

1. Click **Add a scheme**.
2. Choose source type: **Port** or **VLAN**.
3. Select the source ports/VLANs.
4. Select the **destination switch and port** (the port where the Wireshark laptop is
   connected).
5. Save. Traffic is carried over a Transit VLAN between switches.

**Constraints:**
- **One active Traffic Mirror per switch or stack** — adding a second scheme
  deactivates the first.
- The destination port restrictions from §3.1 apply (no LAG destination, no uplink
  destination).
- Cross-switch mirroring consumes uplink bandwidth on the Transit VLAN — factor this
  into high-traffic investigations.

### 3.3 Physical TAP (for wire-rate, lossless capture)

For investigations that require **true wire-rate lossless capture** (e.g., validating
every frame on a heavily loaded link), insert a passive network TAP between the device
under test and its upstream port. The TAP passively copies all traffic to a monitor
port without affecting the production path. Wireshark connects to the TAP's monitor
port.

A physical TAP is the highest-fidelity option and bypasses all Dashboard and
SPAN-related limitations.

---

## 4. Quick Decision Guide

| Scenario | Recommended approach |
|---|---|
| Quick one-shot diagnostic, MX or MS traffic | Dashboard capture → Download .pcap |
| East-west (same-VLAN, client-to-client) | MS Dashboard capture **or** SPAN/TAP |
| Continuous live feed into Wireshark | SPAN (§3.1 or §3.2) or physical TAP |
| Wire-rate, lossless, highest fidelity | Physical TAP |
| MR wireless captures | Network-wide > Monitor > Intelligent Capture |

---

## Sources

- [Packet Capture Overview](https://documentation.meraki.com/Platform_Management/Dashboard_Administration/Troubleshooting_and_Support/Troubleshooting/Packet_Capture_Overview)
- [Getting started on Packet Captures with Wireshark](https://documentation.meraki.com/Platform_Management/Dashboard_Administration/Troubleshooting_and_Support/Troubleshooting/Getting_started_on_Packet_Captures_with_Wireshark)
- [MS Packet Captures and Port Mirroring on the MS Switch](https://documentation.meraki.com/Switching/MS_-_Switches/Operate_and_Maintain/Monitoring_and_Reporting/Packet_Captures_and_Port_Mirroring_on_the_MS_Switch)
- [Traffic Mirroring](https://documentation.meraki.com/Switching/MS_-_Switches/Operate_and_Maintain/Monitoring_and_Reporting/Traffic_Mirroring)
