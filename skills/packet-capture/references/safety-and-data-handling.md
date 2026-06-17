# Safety & Data Handling

> **Read this before running any capture.** These rules apply regardless of platform
> (Windows, ESXi, VCSA, Meraki, or any other target in your environment).

---

## 1. Authorization first

- **Confirm you are authorized** to capture on the target host and network segment
  before issuing a single command. Capturing on networks or hosts you do not own or
  administer may be illegal (e.g. CFAA, ECPA, and equivalent national statutes).
- Authorization gate checklist (clear all before starting):
  - [ ] You own or are an authorized admin of the target host.
  - [ ] You own or are an authorized admin of the network segment being tapped.
  - [ ] The capture is scoped to the investigation — not standing or continuous.
  - [ ] If a maintenance window or change ticket is required, it is open.

---

## 2. What a capture exposes

A raw packet capture is sensitive data. Treat it accordingly.

| What's in the wire | Why it matters |
|---|---|
| Kerberos AS-REQ / TGT exchanges | Offline-crackable (AS-REP roasting) if pre-auth is off; TGT material otherwise |
| NTLM challenge/response hashes | Offline-crackable (hashcat, John) at any time |
| SMB session headers | Session keys, share names, file paths, user SIDs |
| Cleartext HTTP cookies and Bearer tokens | Direct session hijack |
| SNMP community strings (v1/v2c) | Read (or write) access to every SNMP-managed device |
| Internal hostnames and topology | FQDN, IP, VLAN, trust boundary data for a future attacker |
| PII in application payloads | Names, addresses, SSNs, health data depending on application |

**Rule of thumb:** a single capture of an AD domain-join or user logon contains
credential-equivalent material. Handle it like a password database — encrypt at
rest, share only over an encrypted channel, delete when done.

---

## 3. Bound the blast radius

Minimize how much you capture and for how long.

- **Capture filters over display filters.** A BPF capture filter drops packets
  at the kernel/driver before they are written to disk. A display filter just hides them
  in Wireshark — the sensitive bytes are already in the file. Write the filter first,
  then start the capture.

- **Shortest duration that reproduces the issue.**
  Trigger the specific failure once, then stop.

- **Hard caps — always set at least one:**
  - Packet count: `-c <N>` (pktmon uses `--pkt-size`; pktcap-uw uses `-c`; tcpdump uses `-c`)
  - File size: `maxSize=<MB>` (netsh trace) or `-G <seconds>` with `-W <files>` rolling ring buffer (tcpdump/tshark)
  - Time: schedule a `pktmon stop` or `tcpdump` timeout if interactive stop is not guaranteed

- **Snaplen reduction** — use only when headers alone suffice (e.g. routing/ARP diagnosis).
  Setting `-s 68` or similar will save space but destroys application-layer evidence.
  For auth and application issues, always use `-s 0` (full frame).

---

## 4. Handling and sharing

### Storage
- Store captures in a **dedicated local capture directory** (e.g. `<CAP-DIR>\captures\`).
- That directory must be **gitignored** (`*.pcap`, `*.pcapng`, `*.etl`, `*.cap`, `captures/`).
  Verify `.gitignore` before writing any capture to a path inside a repo working tree.
- Encrypt the directory at rest if the host is a shared workstation or laptop.

### Never do this
- **Never commit** a raw pcap to any git repository (public or private).
- **Never upload** a raw pcap to a public ticket, GitHub issue, Slack channel, or chat tool.
- **Never paste** hex dumps or decoded frames containing auth material into a ticket.

### Sanitize before sharing
When you need to share a trace with a vendor or colleague, share only the relevant slice:

```bash
# Share only the packets that match the symptom, stripping everything else
tshark -r <CAP-DIR>\cap.pcapng -Y "<display-filter>" -w <CAP-DIR>\share-slice.pcapng

# Full anonymization (MACs, IPs, payloads): use TraceWrangler (GUI, Windows)
# https://www.tracewrangler.com/

# editcap can truncate payloads (snaplen reduction after the fact):
editcap -s 96 <CAP-DIR>\cap.pcapng <CAP-DIR>\cap-hdr-only.pcapng
```

### Retention and deletion
- Delete captures as soon as the investigation closes. Do not archive "for later".
- If a capture must be retained (e.g. for an audit or incident), move it to an
  encrypted evidence store and log who has access.

---

## 5. Disable what you enabled

Restore every temporary access you opened during the investigation.

| What you enabled | How to revert |
|---|---|
| ESXi SSH | GUI: Host > Configure > System > Services > SSH > Stop; or `vim-cmd hostsvc/stop_ssh` |
| VCSA SSH | VAMI `https://<VCSA>:5480` > Access > Deactivate SSH Login; or `ssh.set --enabled false` in appliancesh |
| VCSA bash shell (`chsh -s /bin/bash root`) | `chsh -s /bin/appliancesh root` (revert before closing SSH) |
| pktmon filters (Windows) | `pktmon filter remove` (clears ALL filters; verify with `pktmon filter list`) |
| netsh trace session | `netsh trace stop` (stops and writes the .etl; the session auto-clears) |
| Meraki port mirror / Traffic Mirroring | Dashboard: remove the mirror rule; re-enable the destination port for normal use |

**Check before you close the ticket:** run `pktmon filter list` on any Windows host
where you ran a capture and confirm the list is empty. Orphaned pktmon filters persist
across reboots and will silently affect traffic until cleared.

---

*Next: [Capture placement](capture-placement.md) — choose where to tap before picking a tool.*
