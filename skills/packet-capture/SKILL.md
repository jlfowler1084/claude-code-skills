---
name: packet-capture
description: >
  Multi-platform packet capture and analysis skill: capture packets, sniff traffic,
  run wireshark, tshark, tcpdump, pktmon, pcap — without installing software on
  remote hosts. Use when troubleshooting "why isn't X reaching Y", packet loss,
  DHCP not working, DNS failing, TCP resets, auth issues, slow traffic, or any
  scenario where you need to prove or disprove whether packets are flowing. Covers
  Windows laptop (Wireshark/TShark), Windows Server 2019+/2022/2025 (pktmon),
  Windows Server 2016 (netsh trace + etl2pcapng), ESXi host capture (pktcap-uw /
  tcpdump-uw), vCenter VCSA capture (tcpdump on Photon OS), and Cisco Meraki
  (Dashboard capture / SPAN). Core approach: capture remotely using built-in tools,
  pull the .pcap locally, analyze in Wireshark. Activate on any network troubleshoot
  request involving packet-level evidence.
---

# Packet Capture Skill

Portable, no-install-first packet capture across Windows, ESXi/vCenter, and Meraki —
captured remotely, analyzed locally in Wireshark.

---

## Safety & Authorization Gate — DO THIS FIRST

Before any capture:

1. **Confirm authorization.** You must have explicit permission to capture on the
   target host and network segment. Captures may contain credentials and PII.
2. **Bound scope and size.** Apply a capture filter to limit traffic. Set a packet
   count (`-c`) or time limit (`-G`) to prevent runaway files.
3. **Never upload raw pcaps** to public services (paste sites, AI chat). Sanitize
   with `editcap`/`TraceWrangler` before sharing externally.

Full guidance: `references/safety-and-data-handling.md`

---

## Three Principles

- **Capture remotely, analyze locally** — transfer the `.pcap` to your workstation
  and open it in Wireshark. Never rely solely on CLI output for deep analysis.
- **No-install-first** — every platform listed below has a built-in capture tool.
  Reach for it before installing anything.
- **Placement before filters** — choose the right capture point first; a perfect
  filter at the wrong interface proves nothing.

---

## Step 1 — Load Local Context

```
copy local-context.template.md local-context.md
```

`local-context.md` is gitignored. Fill it with your environment's IPs, hostnames,
interface names, and VLAN IDs so every subsequent step uses real values.

---

## Step 2 — Choose the Capture Point

Tap close to the problem, on **both sides** of the suspected drop.
If a packet leaves the sender but never arrives, a two-sided capture pinpoints
exactly which hop is swallowing it.

Full decision tree and matrix: `references/capture-placement.md`

---

## Step 3 — Capture (No-Install-First Matrix)

| Platform | No-install method | Reference |
|---|---|---|
| Windows laptop / desktop | Wireshark / TShark (hub tool) | `references/windows.md` |
| Windows Server 2019+ / 2022 / 2025 | `pktmon` (inbox) | `references/windows.md` |
| Windows Server 2016 | `netsh trace` → `etl2pcapng` | `references/windows.md` |
| ESXi host | `pktcap-uw` (vmk/vnic) · `tcpdump-uw` | `references/esxi-vcenter.md` |
| vCenter VCSA (Photon OS) | `tcpdump` via SSH + shell | `references/esxi-vcenter.md` |
| Cisco Meraki | Dashboard packet capture · SPAN port | `references/meraki.md` |

**Transfer captured files** to your workstation with `scp` / WinSCP / PSCP,
then open in Wireshark.

---

## Step 4 — Filter

Apply a **capture filter (BPF)** at capture time to reduce file size, then narrow
further with **display filters** in Wireshark after the fact.

Quick examples:

| Goal | Filter (BPF or display) |
|---|---|
| All traffic for one host | `host <TARGET-IP>` |
| DNS only | `port 53` |
| TCP resets | `tcp.flags.reset==1` (display) |

Full indexed cookbook (BPF + Wireshark display, cross-tool syntax):
`references/filter-cookbook.md`

---

## Step 5 — Analyze

Open the `.pcap` in Wireshark. Triage order:

1. **Statistics > Protocol Hierarchy** — confirm traffic mix, spot unexpected protocols.
2. **Statistics > Conversations** — identify top talkers and unexpected flows.
3. **Analyze > Expert Information** — surface retransmissions, resets, zero-window at a glance.
4. **Follow Stream** (right-click a packet) — read full TCP/UDP/TLS stream in context.

Full workflow with TCP graphs, IO graphs, and field extraction:
`references/analysis-workflow.md`

---

## Reference Index

- `references/safety-and-data-handling.md` — authorization, scope bounding, sanitization, no-upload rule
- `references/capture-placement.md` — where to tap; decision tree; two-sided capture rationale
- `references/filter-cookbook.md` — BPF and Wireshark display filters; cross-tool syntax
- `references/analysis-workflow.md` — Protocol Hierarchy, Expert Info, TCP graphs, field extraction
- `references/windows.md` — pktmon, netsh trace, etl2pcapng, PS-remoting capture
- `references/esxi-vcenter.md` — pktcap-uw, tcpdump-uw (ESXi); tcpdump on VCSA Photon OS
- `references/meraki.md` — Dashboard capture, .pcap download, SPAN, fidelity caveats
