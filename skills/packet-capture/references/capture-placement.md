# Capture Placement Guide

Knowing WHERE to capture is more important than knowing what filter to use.
Wrong placement means missing packets entirely.

## The Golden Rule

**Capture as close to the problem as possible, on both sides of the suspected
failure point.** If you think a router or firewall is dropping inter-subnet
traffic, capture on BOTH the ingress interface AND the egress interface
simultaneously (run two capture sessions or two capture files). Absence of
packets on one side proves the drop location.

---

## Generic Capture Points

The table below maps common symptom classes to the capture point most likely to
reveal the cause. For the actual capture commands on each platform, see the
platform reference files (`references/windows.md`, `references/esxi-vcenter.md`,
`references/meraki.md`).

| Capture point | Best for |
|---|---|
| **Endpoint NIC** (laptop / server / VM guest) | Client-side perspective: what the host actually sends and receives; DHCP lease, DNS, authentication |
| **Virtual switch / uplink** (ESXi vSwitch) | Seeing raw 802.1Q tags; detecting VLAN misconfigurations; verifying whether a VM's frames leave the hypervisor |
| **Router / firewall hop** (each interface) | Inter-subnet routing verification; NAT analysis; routing-loop detection; firewall-drop confirmation |
| **Switch port mirror** (SPAN / TAP) | Physical-layer view; east-west traffic between hosts on the same VLAN; events that never reach a routed interface |
| **Appliance management NIC** (vCenter, storage, etc.) | Traffic to/from the appliance's own management stack; certificate handshakes; API calls |

---

## Decision Tree

Use symptom as the entry point. Choose the **two** capture points listed — run
both simultaneously (see Multi-point section below). Vendor-specific commands
are in the platform reference files.

```
Symptom
│
├─ "No L2 connectivity / ARP not resolving"
│   └── Capture on: SOURCE endpoint NIC + DESTINATION endpoint NIC
│       Filter: arp
│       Diagnostic: if ARP request leaves source but no reply arrives → L2 drop
│       (VLAN mismatch, switch port config, or destination host rejecting ARP)
│
├─ "DHCP not assigning addresses"
│   └── Capture on: CLIENT endpoint NIC + DHCP SERVER NIC
│       Filter: port 67 or port 68
│       Diagnostic: if Discover arrives at server with hops > 0 → relay is working;
│       if server-side only sees hops == 0 → relay not configured or disabled;
│       if no Discover at server → packet never left the client segment
│
├─ "DNS resolution failing"
│   └── Capture on: CLIENT NIC + DNS SERVER NIC (compare both)
│       Filter: port 53
│       Diagnostic: query present at client but absent at server → routing/firewall drop;
│       query at server but no response → resolver unreachable or zone missing
│
├─ "TCP RST / connection refused / no SYN-ACK"
│   └── Capture on: INITIATING endpoint NIC + LISTENING endpoint NIC
│       Filter: tcp.flags.reset == 1  OR  (tcp.flags.syn==1 and tcp.flags.ack==0)
│       Diagnostic: SYN at client, no SYN at server → path drop;
│       SYN at server, RST back → server not listening or firewall on the server
│
├─ "Slow performance / packet loss"
│   └── Capture on: BOTH endpoints simultaneously
│       Filter: tcp.analysis.flags  (Expert Info view)
│       Diagnostic: retransmissions and duplicate ACKs point to the loss direction;
│       zero-window events indicate buffer exhaustion on the receiver side;
│       use Statistics > TCP Stream Graphs > RTT to pinpoint latency source
│
├─ "Inter-subnet (VLAN / routing) drop"
│   └── Capture on: ROUTER ingress interface for the source subnet
│                  + ROUTER egress interface for the destination subnet
│       Filter: icmp or host <TARGET-IP>
│       Diagnostic: if traffic arrives on ingress but never on egress → routing
│       rule missing, ACL drop, or misconfigured VLAN subinterface;
│       if traffic never arrives on ingress → upstream L2 issue
│
├─ "No internet / NAT failure"
│   └── Capture on: ROUTER WAN interface (outside)
│       Filter: not net <INTERNAL-SUBNET>
│       Diagnostic: if packets leave the WAN interface but no reply arrives →
│       upstream NAT or firewall issue; if packets never reach WAN →
│       no default route or NAT masquerade not configured
│
└─ "Unknown rogue traffic / unexpected talker"
    └── Capture on: SWITCH uplink or virtual switch in promiscuous mode
        Filter: Statistics > Endpoints to enumerate all MAC/IP addresses
        Diagnostic: cross-reference known-host list against the Endpoints table
```

---

## Multi-Point Simultaneous Capture

For the hardest problems, capture at multiple points at the same time. This
lets you prove exactly **where** a packet disappears.

**Procedure:**

1. Identify the **two boundary points** that bracket the suspected drop —
   one on each side (e.g., router ingress and egress; client NIC and server NIC).
2. Start both captures before reproducing the problem.
3. Reproduce the problem exactly once (one ping, one login attempt, one DHCP
   release/renew).
4. Stop both captures.
5. Open both in Wireshark. Apply the same display filter. Compare timestamps
   and packet counts.

**Interpretation key:**

| Observed in capture A? | Observed in capture B? | Conclusion |
|---|---|---|
| Yes | Yes | Packet crossed the boundary — problem is elsewhere |
| Yes | No | Packet dropped between A and B — focus here |
| No | No | Packet never left source — source host or its uplink |
| No | Yes | Asymmetric routing — return path differs from forward path |

**Practical tip:** Start the captures with a packet-count or time limit
(`-c 500`, `maxSize=256`) so they don't grow unbounded. After reproducing
the symptom, stop captures promptly and copy them to the analyst laptop for
Wireshark analysis.
