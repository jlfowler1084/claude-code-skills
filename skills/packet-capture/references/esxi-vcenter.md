# ESXi + vCenter Capture Reference

Capture without installing anything on the host; analyze on the laptop.

Two platforms, two toolsets:
- **ESXi host** — `pktcap-uw` (uplinks + switchports) and `tcpdump-uw` (vmkernel interfaces only).
- **vCenter Server Appliance (VCSA, Photon OS)** — `tcpdump` only (`pktcap-uw` is not present on VCSA).

---

## Part A — ESXi Host (pktcap-uw / tcpdump-uw)

### 1. Enable SSH

SSH is **OFF by default** on ESXi. Re-enabling it raises a host warning in vCenter; disable it again when done.

**GUI (vSphere Client):** Host > Configure > System > Services > SSH > Start

**DCUI (console):** F2 > Troubleshooting Options > Enable SSH

**Shell / remote (via existing DCUI or iDRAC session):**
```bash
vim-cmd hostsvc/enable_ssh && vim-cmd hostsvc/start_ssh
# When done:
vim-cmd hostsvc/stop_ssh
```

### 2. Map ports before capturing

```bash
net-stats -l
```

Output columns: PortNum (use with `--switchport`), uplink name (use with `--uplink`), world name (VM or vmk). Identify your target port before running a capture.

### 3. Capture at an uplink (physical NIC)

```bash
pktcap-uw --uplink <vmnicX> \
  --capture UplinkSndKernel,UplinkRcvKernel \
  -s 0 -c 1000 \
  -o /vmfs/volumes/<datastore>/uplink.pcap
```

- `--capture UplinkSndKernel,UplinkRcvKernel` — both TX and RX directions at the physical uplink. **No spaces** inside the comma-separated list.
- `-s 0` — full frame capture (do not omit: default snaplen truncates payloads).
- `-c 1000` — stop after 1,000 packets (always bound with `-c` or `-G` to prevent runaway captures).
- `-o /vmfs/volumes/<datastore>/…` — write to a real VMFS datastore, not the ESXi ramdisk.

`UplinkSndKernel,UplinkRcvKernel` already covers both TX and RX at the uplink —
`--dir 2` is not needed here. Use `--dir 2` when capturing at a vmkernel interface
or switchport where both directions are not already selected by the `--capture` pair.

### 4. Capture at a switchport (VM vNIC or vmk port)

```bash
pktcap-uw --switchport <portID> \
  --capture VnicTx,VnicRx \
  -s 0 -c 1000 \
  -o /vmfs/volumes/<datastore>/sw.pcap
```

`<portID>` comes from the `net-stats -l` PortNum column.

### 5. Capture at a vmkernel interface (management / iSCSI / vMotion)

`tcpdump-uw` is vmkernel-interface-only (it cannot bind uplinks or switchports):

```bash
tcpdump-uw -i vmk0 -s 0 -w /vmfs/volumes/<datastore>/vmk0.pcap -c 1000
```

Replace `vmk0` with the appropriate vmkernel interface (e.g. `vmk1` for iSCSI, `vmk2` for vMotion). Confirm interface names with `esxcli network ip interface list`.

### 6. Stop a runaway capture

```bash
# Official kill recipe:
kill $(lsof | grep pktcap-uw | awk '{print $1}' | sort -u)

# Or:
pkill pktcap-uw
```

`pktcap-uw` forks a background worker per capture point that keeps running if the terminal is closed or the `-c` limit is not set. Always use the kill recipe to confirm all workers are stopped.

### 7. Copy the capture off to the laptop

```bash
scp root@<ESXI-HOST>:/vmfs/volumes/<datastore>/uplink.pcap <CAP-DIR>\uplink.pcap
```

Then open in Wireshark on the laptop.

### 8. Live to Wireshark over SSH (community pattern — smoke-test first)

> **Note:** This is a community-documented pattern, not officially supported by Broadcom. Smoke-test in your environment before relying on it. The preferred method on Windows is Wireshark's built-in `sshdump` extcap (Edit > Preferences > Advanced > Extcap > sshdump).

Run from **Git Bash or WSL, not PowerShell** — PowerShell mangles the binary pipe:

```bash
ssh root@<ESXI-HOST> "pktcap-uw --uplink <vmnicX> --capture UplinkSndKernel,UplinkRcvKernel -o -" \
  | "C:\Program Files\Wireshark\Wireshark.exe" -k -i -
```

The `-o -` flag sends the pcap stream to stdout. Wireshark's `sshdump` extcap handles the SSH tunnel natively and is the cleaner option on Windows.

---

## Part B — vCenter Server Appliance (Photon OS, tcpdump)

> **Important:** `pktcap-uw` is an ESXi-only tool. It is **not present** on VCSA. Use `tcpdump`.

### 1. Enable SSH on VCSA

**VAMI (web):** `https://<VCSA>:5480` > Access > Activate SSH Login

**appliancesh CLI:**
```bash
ssh.set --enabled true
```

### 2. Connect and enter the bash shell

```bash
ssh root@<VCSA>
```

This lands you in `appliancesh` (a restricted shell). Type `shell` to drop into Photon OS bash where `tcpdump` lives:

```bash
shell
```

On vCenter 6.7 and later, `shell.set` is not required — `shell` at the appliancesh prompt is sufficient.

### 3. Confirm tooling

```bash
which tcpdump      # should be present (e.g. /usr/sbin/tcpdump)
which pktcap-uw    # absent — expected
```

### 4. Identify the management NIC

```bash
ip a
```

The management NIC is usually `eth0`. Confirm before starting a capture.

### 5. Capture to file

```bash
tcpdump -i eth0 -s 0 -w /tmp/vcsa-cap.pcap
```

Add a BPF filter to bound the capture size and reduce noise:

```bash
tcpdump -i eth0 -s 0 -w /tmp/vcsa-cap.pcap host <TARGET-IP> and not port 22
```

- `-s 0` — full frame (old tcpdump defaulted to a 96-byte snaplen; always set this).
- `not port 22` — excludes your own SSH session from the capture.
- `/tmp` may be tmpfs/RAM on VCSA — scope with a BPF filter, keep the file small, and clean up after.

Stop the capture with `Ctrl+C`.

### 6. Copy off to the laptop

```bash
scp root@<VCSA>:/tmp/vcsa-cap.pcap <CAP-DIR>\vcsa-cap.pcap
```

Then open in Wireshark.

### 7. For non-interactive scp / ssh-exec: set root's shell to bash

When running `scp` or `ssh root@<VCSA> "tcpdump …"` without an interactive session, the login shell must be bash (not appliancesh), otherwise the command is rejected:

```bash
chsh -s /bin/bash root
```

**Revert after the capture session:**

```bash
chsh -s /bin/appliancesh root
```

### 8. Live to Wireshark over SSH (community pattern — smoke-test first)

> **Note:** As with ESXi, this is a community pattern. Prefer Wireshark's `sshdump` extcap on Windows. Set root's shell to bash first (step 7).

Run from **Git Bash or WSL, not PowerShell**:

```bash
ssh root@<VCSA> "tcpdump -i eth0 -s 0 -U -w - not port 22" \
  | "C:\Program Files\Wireshark\Wireshark.exe" -k -i -
```

- `-U` (packet-buffered) — flushes each packet to stdout immediately instead of buffering.
- `not port 22` — excludes the SSH control session from the capture stream.

**sshdump (preferred on Windows):** In Wireshark, go to Capture > Options, select the `sshdump` interface, and configure the VCSA hostname and credentials. This avoids the binary-pipe problem entirely.

---

## Gotchas

| # | Gotcha |
|---|--------|
| 1 | `pktcap-uw` forks a background worker per capture point that keeps running. **Always** bound with `-c` (packet count) or `-G` (seconds), or use the `lsof`/`pkill` kill recipe. |
| 2 | Default `pktcap-uw` snaplen truncates payloads. **Always use `-s 0`** for full frames. |
| 3 | **No spaces** in `--capture` lists: `UplinkSndKernel,UplinkRcvKernel` not `UplinkSndKernel, UplinkRcvKernel`. The command silently ignores a direction when there is a space. |
| 4 | `tcpdump-uw` can **only** bind vmkernel interfaces (`vmkN`). It cannot capture uplinks or switchports — use `pktcap-uw` for those. |
| 5 | SSH is **off by default** on ESXi and raises a host warning when enabled. Disable it immediately after the capture session. |
| 6 | Write to a **real VMFS datastore**, not the ESXi ramdisk (`/tmp` on ESXi is RAM-backed and small). |
| 7 | `--dir 2` captures both TX and RX; use it for vmk/switchport captures that need both directions. For uplink captures, `UplinkSndKernel,UplinkRcvKernel` already covers both directions — `--dir 2` is redundant there. |
| 8 | **VCSA lands in `appliancesh`** on SSH login. Type `shell` to reach the Photon OS bash shell where `tcpdump` lives. |
| 9 | Always exclude your SSH session from live pipes: `not port 22`. Otherwise the pcap-data SSH stream captures itself and spirals. |
| 10 | `/tmp` on VCSA may be tmpfs (RAM). Use a BPF filter to keep captures small and delete the file when done. |
| 11 | **Windows binary pipe must use Git Bash or WSL.** PowerShell's pipe corrupts binary data. If you cannot use Git Bash/WSL, capture to file (`-o /vmfs/…` or `-w /tmp/…`) and `scp` off instead. |
| 12 | `pktcap-uw` is **ESXi-only**. It is not present on VCSA. Always use `tcpdump` on VCSA. |

---

## Sources

- [pktcap-uw command syntax (vSphere 8.0)](https://techdocs.broadcom.com/us/en/vmware-cis/vsphere/vsphere/8-0/vsphere-networking/monitoring-network-packets/using-the-pktcap-uw-tool/pktcap-uw-command-syntax.html)
- [pktcap-uw general options / snaplen 0 (vSphere 8.0)](https://techdocs.broadcom.com/us/en/vmware-cis/vsphere/vsphere/8-0/vsphere-networking/monitoring-network-packets/using-the-pktcap-uw-tool/general-options-for-capturing-and-tracing-packets.html)
- [Broadcom KB 341568 — using pktcap-uw (uplink/switchport, kill recipe)](https://knowledge.broadcom.com/external/article/341568/using-the-pktcapuw-tool-in-esxi-55-and-l.html)
- [Broadcom — Enable SSH from vSphere Client (vSphere 8.0)](https://techdocs.broadcom.com/us/en/vmware-cis/vsphere/vsphere-sdks-tools/8-0/getting-started-with-esxcli-8-0/running-host-management-commands-in-the-esxi-shell/remote-esxi-shell-access-with-ssh/enable-ssh-from-the-vsphere-client.html)
- [Broadcom KB 421448 — enable SSH on vCenter Server Appliance via VAMI](https://knowledge.broadcom.com/external/article/421448/how-to-enable-ssh-service-on-vcenter-ser.html)
- [Broadcom KB 408596 — ssh.set (appliancesh)](https://knowledge.broadcom.com/external/article/408596/enabling-ssh-access-when-vsphere-client.html)
- [Broadcom KB 319670 — shell toggle (appliancesh → bash)](https://knowledge.broadcom.com/external/article/319670/toggling-the-vcenter-server-appliance-de.html)
- [Broadcom KB 322847 — tcpdump on VCSA](https://knowledge.broadcom.com/external/article/322847/troubleshooting-tools-for-networking-on.html)
- [Broadcom KB 307364 — pktcap-uw (ESXi) vs tcpdump (VCSA)](https://knowledge.broadcom.com/external/article/307364/verify-esxi-host-heartbeat-to-vcen.html)
- [Wireshark sshdump extcap](https://www.wireshark.org/docs/man-pages/sshdump.html)
