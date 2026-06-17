# Windows Packet Capture Reference

> Capture on the server without installing Wireshark; analyze on your laptop.

---

## Pick your method

| Platform | Tool | Notes |
|---|---|---|
| Windows 11 | **pktmon** | In-box; full filter + etl2pcap surface |
| Windows Server 2025 | **pktmon** | In-box |
| Windows Server 2022 | **pktmon** | In-box |
| Windows Server 2019 | **pktmon** | In-box since Server 2019 / Win10 1809 (build 17763); full filter/etl2pcap surface at build 2004 (19041)+ |
| Windows 10 (1809+) | **pktmon** | Same baseline as Server 2019 |
| **Windows Server 2016** | **netsh trace** | **pktmon is NOT present on Server 2016** — use netsh trace (§2) |

**Rule of thumb:** Server 2019 / Win10 1809 / Win11 → `pktmon`. Server 2016 → `netsh trace`.

---

## 1. pktmon (Server 2019+ / Win10 1809+ / Win11)

Run all commands in an **elevated** (`Run as Administrator`) PowerShell or CMD session.

### Add filters (before starting)

```powershell
# Add a filter BEFORE starting the capture.
# Filters are global; up to 32; a packet matches if ALL conditions in one filter are met.
pktmon filter add MyHost -i <TARGET-IP>    # -i ip (CIDR ok), -p port, -t TCP SYN, -m mac, -v vlan
pktmon filter list                          # inspect current filters
pktmon filter remove                        # clears ALL filters (run between captures)
```

### Start, stop, convert

```powershell
# Start capture
# --pkt-size 0  = FULL packet bytes (default 128 TRUNCATES payloads — always override)
# --comp nics   = capture only at the NIC layer (de-duplicates; default --comp all records each packet
#                 at every stack layer, producing many duplicates)
pktmon start --capture --pkt-size 0 --comp nics --file-name <CAP-DIR>\cap.etl

# ... reproduce the problem once ...

pktmon stop

# Convert ETL -> pcapng for Wireshark
# CURRENT verb is etl2pcap; 'pktmon pcapng' is legacy on older builds
pktmon etl2pcap <CAP-DIR>\cap.etl --out <CAP-DIR>\cap.pcapng

# Dropped packets are EXCLUDED from the default output; to inspect them separately:
pktmon etl2pcap <CAP-DIR>\cap.etl --drop-only --out <CAP-DIR>\cap-drops.pcapng
```

### Remote capture via WinRM (no install, no interactive logon)

Use `New-PSSession` to run pktmon on the target server and copy the file back without touching it locally.

```powershell
# 1. Open a session to the remote server (prompts for credentials)
$s = New-PSSession -ComputerName <SERVER> -Credential (Get-Credential)

# 2. Start the capture remotely
Invoke-Command -Session $s -ScriptBlock {
    pktmon filter add -i <TARGET-IP>
    pktmon start --capture --pkt-size 0 --file-name C:\Captures\cap.etl
}

# 3. Reproduce the problem, then stop and convert
Invoke-Command -Session $s -ScriptBlock {
    pktmon stop
    pktmon etl2pcap C:\Captures\cap.etl --out C:\Captures\cap.pcapng
}

# 4. Copy the pcapng to the analyst laptop
Copy-Item -FromSession $s -Path C:\Captures\cap.pcapng -Destination <CAP-DIR>\cap.pcapng
Remove-PSSession $s
```

**Alternative (no WinRM):** If WinRM is unavailable, copy the `.etl` or `.pcapng` via the admin share:
`\\<SERVER>\C$\Captures\cap.pcapng`

---

## 2. netsh trace (Server 2016)

Run from an **elevated** CMD prompt. pktmon is not present on Server 2016 — use netsh trace.

### Capture on the server

```cmd
:: ON THE SERVER (elevated CMD)
:: capture=yes drives the ndiscap provider (raw packet capture)
:: report=disabled keeps the output light (skips the diagnostics report)
netsh trace start capture=yes report=disabled persistent=no maxSize=512 fileMode=circular traceFile=C:\Traces\cap.etl

:: Optional capture filter to shrink the .etl (only honored with capture=yes):
::   ... IPv4.Address=<TARGET-IP>
:: See all available filter keys:
::   netsh trace show CaptureFilterHelp

:: ... reproduce the problem ...
netsh trace stop
```

### Convert on the analyst laptop

The `.etl` file is not a pcap. Convert it **off-box** on your Windows laptop using Microsoft's `etl2pcapng.exe`.

```cmd
:: ON THE ANALYST LAPTOP
:: Get etl2pcapng.exe from: https://github.com/microsoft/etl2pcapng/releases
:: (v1.11.0, statically linked — no dependencies)
etl2pcapng.exe cap.etl cap.pcapng
```

etl2pcapng parses the `.etl` file directly — no live session or remote connection is needed for conversion.

---

## 3. Gotchas

### pktmon gotchas

- **`--pkt-size 0` is mandatory.** The default snaplen is 128 bytes — enough for headers but not payloads. Always pass `--pkt-size 0` to capture full frames.
- **`etl2pcap` is lossy.** The conversion discards pktmon metadata. Dropped packets are excluded from the default output unless you add `--drop-only`.
- **`--comp all` duplicates packets.** The default records every packet at every stack layer. Use `--comp nics` to capture once at the NIC and avoid noise.
- **Filters persist across runs.** Always run `pktmon filter remove` between captures to start clean.
- **Elevation is required locally AND remotely.** UAC token filtering can strip admin rights from LOCAL accounts in remote sessions — use a domain admin or the built-in Administrator account for `Invoke-Command`.
- **Default log mode is circular at 512 MB.** Use `--file-name` and monitor size for long captures.
- **Wireshark 3.x+ can open raw `.etl` directly**, but `etl2pcap` is the documented conversion path and is more reliable.
- **`pktmon pcapng` is the legacy verb** on older builds — if `etl2pcap` is not recognized, try `pktmon pcapng` and check your OS build with `winver`.

### netsh trace gotchas

- **`capture=yes` is mandatory.** Without it, netsh trace collects ETW diagnostic events only — no raw packets.
- **Elevated only.** The `ndiscap` provider requires Administrator privileges.
- **One trace session at a time.** If a trace is already running, `netsh trace start` fails. Check with `netsh trace show status`.
- **The `.cab` file is not packet data.** `netsh trace stop` produces both a `.etl` and a `.cab` diagnostic bundle — you only need the `.etl` for conversion.
- **`fileMode=circular` overwrites oldest data at `maxSize`.** If you need a hard cap with no overwrite, use `fileMode=single`.
- **Convert off-box.** Run `etl2pcapng.exe` on your analyst laptop — you do not need to install anything on the server.
- **A scenario trace pulls in many ETW providers** (noise). Using `capture=yes` alone with a capture filter keeps the output focused on packets.
- **etl2pcapng per-packet PID comments are unreliable** for process attribution — treat them as hints only.

---

## Sources

- [pktmon command reference](https://learn.microsoft.com/windows-server/administration/windows-commands/pktmon)
- [pktmon start](https://learn.microsoft.com/windows-server/administration/windows-commands/pktmon-start)
- [pktmon etl2pcap](https://learn.microsoft.com/windows-server/administration/windows-commands/pktmon-etl2pcap)
- [pktmon filter add](https://learn.microsoft.com/windows-server/administration/windows-commands/pktmon-filter-add)
- [Pktmon overview](https://learn.microsoft.com/windows-server/networking/technologies/pktmon/pktmon)
- [netsh trace](https://learn.microsoft.com/windows-server/administration/windows-commands/netsh-trace)
- [Using Netsh to manage traces](https://learn.microsoft.com/windows/win32/ndf/using-netsh-to-manage-traces)
- [microsoft/etl2pcapng (GitHub)](https://github.com/microsoft/etl2pcapng)
- [etl2pcapng v1.11.0 binary](https://github.com/microsoft/etl2pcapng/releases/download/v1.11.0/etl2pcapng.exe)
