# Filter Cookbook

All display filters use Wireshark display-filter syntax unless labeled otherwise.
BPF capture filters (used with `tcpdump`, `tshark -f`, `pktcap-uw --filter`, etc.)
are labeled **BPF** and follow libpcap syntax.

Replace placeholder tokens with your environment values:
- `<TARGET-IP>` — the IP address of the host you are investigating
- `<SUBNET>` — a CIDR subnet, e.g. `10.0.20.0/24`
- `<MAC>` — a MAC address, e.g. `aa:bb:cc:dd:ee:ff`

---

## DHCP / BOOTP

### Display Filters
```
# All DHCP/BOOTP
bootp

# Only Discover (client looking for a server)
bootp.option.dhcp == 1

# Only Offer
bootp.option.dhcp == 2

# Only Request
bootp.option.dhcp == 3

# Only ACK (lease granted)
bootp.option.dhcp == 5

# Only NAK (server refused)
bootp.option.dhcp == 6

# Relay agent packets (Hops > 0 means passed through a relay)
bootp.hops >= 1

# Filter by relay agent IP (the relay agent's own address)
bootp.ip.relay == <TARGET-IP>

# Specific client by MAC address
bootp.hw.mac_addr == <MAC>

# DHCP traffic to/from a specific server
bootp and ip.addr == <TARGET-IP>
```

### BPF Capture Filters
```
# All DHCP
port 67 or port 68

# DHCP from a specific client
ether host <MAC> and (port 67 or port 68)
```

### What to Look For
- **Normal relay:** Client Discover → relay increments Hops → server receives
  with `bootp.hops == 1` and `bootp.ip.relay` = relay agent IP → Offer sent
  back to relay → ACK completes.
- **No relay:** Server only sees `bootp.hops == 0` → relay not configured.
- **NAK:** Server rejected request → check scope exhaustion or IP conflict.
- **No ACK:** Offer sent but client silent → VLAN tagging mismatch or client
  NIC issue.

---

## DNS

### Display Filters
```
# All DNS
dns

# Queries only
dns.flags.response == 0

# Responses only
dns.flags.response == 1

# Any error (NXDOMAIN=3, SERVFAIL=2, REFUSED=5, NOTAUTH=9)
dns.flags.rcode != 0

# NXDOMAIN (name does not exist)
dns.flags.rcode == 3

# SERVFAIL (server-side error, forwarder unreachable)
dns.flags.rcode == 2

# AD Kerberos SRV records (critical for domain authentication)
dns.qry.name contains "_kerberos._tcp"

# AD LDAP SRV records (critical for domain join and GPO)
dns.qry.name contains "_ldap._tcp"

# A record queries
dns.qry.type == 1

# SRV record queries
dns.qry.type == 33

# DNS to/from a specific server
dns and ip.addr == <TARGET-IP>

# Slow DNS responses (> 100 ms)
dns.time > 0.1
```

### BPF Capture Filters
```
# All DNS
port 53

# DNS excluding a known host (e.g. to see only forwarder traffic)
port 53 and not host <TARGET-IP>
```

### What to Look For
- **Normal:** Query (QR=0) → Response (QR=1) with answer section, RCode=0.
- **No response:** Query in capture but no matching reply → server unreachable
  or DNS service down.
- **NXDOMAIN on AD SRV names:** AD DNS zone missing or client pointed to wrong
  DNS server.
- **SERVFAIL:** Server cannot reach its forwarders → check routing or firewall.

---

## TCP Connectivity

### Display Filters
```
# TCP SYN (connection attempt)
tcp.flags.syn == 1 and tcp.flags.ack == 0

# TCP SYN/ACK (connection accepted)
tcp.flags.syn == 1 and tcp.flags.ack == 1

# TCP RST (refused or abruptly terminated)
tcp.flags.reset == 1

# TCP FIN (graceful close)
tcp.flags.fin == 1

# Retransmissions (packet loss indicator)
tcp.analysis.retransmission

# Duplicate ACKs (loss or reordering)
tcp.analysis.duplicate_ack

# Zero window (receiver buffer full, sender throttled)
tcp.analysis.zero_window

# Fast retransmission (within 20 ms of dup ACK)
tcp.analysis.fast_retransmission

# All TCP analysis flags at once (Expert Info equivalent)
tcp.analysis.flags

# Follow a specific TCP stream (replace 0 with stream index)
tcp.stream eq 0
```

### BPF Capture Filters
```
# TCP RST packets
tcp[13] & 4 == 4

# TCP SYN packets
tcp[13] & 2 == 2

# Specific host — all TCP
tcp and host <TARGET-IP>
```

---

## ICMP / Routing Diagnostics

### Display Filters
```
# All ICMP
icmp

# Ping requests
icmp.type == 8

# Ping replies
icmp.type == 0

# Destination unreachable (routing failure signal)
icmp.type == 3

# Host unreachable (code 1)
icmp.type == 3 and icmp.code == 1

# Network unreachable (code 0)
icmp.type == 3 and icmp.code == 0

# Port unreachable (code 3)
icmp.type == 3 and icmp.code == 3

# TTL exceeded (traceroute hops)
icmp.type == 11

# ICMP between two specific hosts
icmp and ip.src == <TARGET-IP>
```

### BPF Capture Filters
```
icmp

# ICMP from a specific subnet
icmp and src net <SUBNET>
```

---

## ARP (Layer 2 Troubleshooting)

### Display Filters
```
# All ARP
arp

# ARP requests (who-has)
arp.opcode == 1

# ARP replies (is-at)
arp.opcode == 2

# ARP for a specific host
arp.dst.proto_ipv4 == <TARGET-IP> or arp.src.proto_ipv4 == <TARGET-IP>

# Gratuitous ARP (IP conflict detection)
arp.isgratuitous == 1
```

### What to Look For
- **No ARP reply:** Host unreachable at L2 — VLAN tagging mismatch or host on
  wrong virtual/physical switch segment.
- **Multiple ARP replies for the same IP:** IP address conflict.
- **ARP for the default gateway with no reply:** Router interface not up or
  wrong VLAN tag on host NIC.

---

## VLAN Tagging (802.1Q)

These filters work when capturing on a trunk interface in promiscuous mode.

### Display Filters
```
# All 802.1Q tagged traffic
vlan

# Specific VLAN
vlan.id == <VLAN-ID>

# Traffic on a VLAN involving a specific host
vlan.id == <VLAN-ID> and ip.addr == <TARGET-IP>
```

---

## NAT / WAN

### Display Filters
```
# Traffic involving the router WAN IP
ip.addr == <WAN-IP>

# Traffic leaving the local network (post-NAT)
ip.src == <WAN-IP> and not ip.dst == <INTERNAL-SUBNET>

# Return traffic from outside
ip.dst == <WAN-IP>
```

### BPF Capture Filters
```
# WAN link only (capture on the outside interface)
host <WAN-IP>

# Exclude internal traffic
not net <INTERNAL-SUBNET>
```

---

## Active Directory / Kerberos / NTLM / LDAP / SMB

### Display Filters
```
# Kerberos (preferred AD authentication method)
kerberos

# NTLM (fallback — should be rare in a healthy AD environment)
ntlmssp

# LDAP (directory queries, Group Policy, domain join)
ldap

# LDAP to/from a specific domain controller
ldap and ip.addr == <TARGET-IP>

# LDAPS (encrypted LDAP, port 636)
ip.addr == <TARGET-IP> and tcp.port == 636

# SMB (file shares, SYSVOL, NETLOGON)
smb2

# Kerberos AS-REQ (initial TGT request — user logging on)
kerberos.msg_type == 10

# Kerberos AS-REP (KDC response with TGT)
kerberos.msg_type == 11

# Kerberos TGS-REQ (service ticket request)
kerberos.msg_type == 12

# Kerberos error (wrong password, account locked, clock skew)
kerberos.msg_type == 30

# All AD auth protocols together
kerberos or ntlmssp or ldap or smb2

# AD auth to/from a specific domain controller
(kerberos or ntlmssp or ldap or smb2) and ip.addr == <TARGET-IP>
```

### What to Look For
- **Normal logon:** AS-REQ → AS-REP (TGT issued) → TGS-REQ → TGS-REP
  (service ticket issued) → SMB session established.
- **Clock skew (KRB_AP_ERR_SKEW):** Kerberos error type 37 → sync clocks
  across all hosts (Kerberos tolerance is 5 minutes).
- **Wrong password (KRB5KDC_ERR_PREAUTH_FAILED):** Error type 24.
- **NTLM fallback with no Kerberos:** DNS SRV lookup for `_kerberos._tcp`
  failed — check AD DNS zone.
- **No LDAP at all on domain join:** TCP RST on port 389 → firewall blocking
  LDAP or service not running.

---

## Windows-Admin Filters

```
# Remote Desktop Protocol
tcp.port == 3389

# WinRM (HTTP / HTTPS)
tcp.port == 5985 or tcp.port == 5986

# SMB (file shares, named pipes, DCERPC)
tcp.port == 445

# RPC Endpoint Mapper
tcp.port == 135

# DNS
tcp.port == 53 or udp.port == 53

# LDAP
tcp.port == 389 or udp.port == 389

# LDAPS
tcp.port == 636

# Kerberos
tcp.port == 88 or udp.port == 88

# All Windows remote-management ports at once
tcp.port in {135 389 445 636 3389 5985 5986}
```

---

## Useful Filter Combinations

```
# "Why can't the client reach the server?" — full diagnostic sweep
ip.addr == <TARGET-IP> and
  (arp or icmp or dns or bootp or kerberos or ldap or smb2 or tcp.flags.reset==1)

# "Is inter-subnet routing working?" — traffic from one subnet to another
(ip.src >= <SRC-SUBNET-START> and ip.src <= <SRC-SUBNET-END> and
 ip.dst >= <DST-SUBNET-START> and ip.dst <= <DST-SUBNET-END>)

# "Show me all errors" — TCP + DNS + ICMP unreachable
tcp.analysis.flags or dns.flags.rcode != 0 or icmp.type == 3

# "Is this a firewall drop?" — SYN with no SYN/ACK, plus RSTs
(tcp.flags.syn==1 and tcp.flags.ack==0) or tcp.flags.reset==1
```

---

## Cross-Tool Filter Translation

The same intent expressed in four syntaxes. Use the column that matches your
capture tool.

> **Note on pktmon:** `pktmon filter add` matches on source **or** destination
> (it does not distinguish; a host filter matches either direction). This is
> sufficient for most diagnosis — combine with Wireshark display filters
> after converting the `.etl` to `.pcapng`.

| Intent | Wireshark display filter | BPF (tcpdump / tshark -f) | pktmon filter add | netsh trace capture filter |
|---|---|---|---|---|
| **Host** — traffic to/from one IP | `ip.addr == <TARGET-IP>` | `host <TARGET-IP>` | `pktmon filter add HostFilter -i <TARGET-IP>` | `IPv4.Address=<TARGET-IP>` |
| **DNS only** — UDP/TCP port 53 | `dns` | `port 53` | `pktmon filter add DNS -p 53` | `Protocol.Value=17 and UDP.DestinationPort=53` |
| **SMB only** — TCP port 445 | `tcp.port == 445` | `tcp port 445` | `pktmon filter add SMB -p 445 -t TCP` | `Protocol.Value=6 and TCP.DestinationPort=445` |

**pktmon syntax reference:**
```
pktmon filter add <Name> [-i <IP>] [-p <Port>] [-t TCP|UDP|ICMP|...] [-m <MAC>] [-v <VLAN>]
pktmon filter list      # inspect active filters
pktmon filter remove    # clear ALL filters (no selective removal)
```

**netsh capture filter reference:**
```
netsh trace start capture=yes report=disabled \
  IPv4.Address=<TARGET-IP>
# Combine with AND: IPv4.Address=<IP> and TCP.DestinationPort=<PORT>
# Full filter help: netsh trace show CaptureFilterHelp
```

---

## AD Service Port Reference

| Service | Port | Protocol |
|---|---|---|
| Kerberos | 88 | TCP/UDP |
| DNS | 53 | TCP/UDP |
| LDAP | 389 | TCP/UDP |
| LDAPS | 636 | TCP |
| SMB/CIFS | 445 | TCP |
| RPC Endpoint Mapper | 135 | TCP |
| NetBIOS | 137–139 | TCP/UDP |
| Global Catalog | 3268 | TCP |
| Global Catalog SSL | 3269 | TCP |
| NTP | 123 | UDP |
| RDP | 3389 | TCP |
| WinRM (HTTP) | 5985 | TCP |
| WinRM (HTTPS) | 5986 | TCP |
