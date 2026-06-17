# Analysis Workflow

This reference covers the Wireshark analysis menus and TShark CLI patterns
used to make sense of a capture file after collecting it on the analyst laptop.

---

## Statistics Menus

These windows surface patterns faster than reading individual packets.

| Menu | Use when |
|---|---|
| **Statistics > Protocol Hierarchy** | First sanity check: confirm the traffic mix looks right. Unexpected protocols (e.g. STP flooding, LLMNR storms, excess ARP) jump out as disproportionate percentages. |
| **Statistics > Conversations** | Identify top-talking pairs (by packet count and bytes). Reveals unexpected flows, asymmetric byte counts, and cross-segment talkers that should not be there. |
| **Statistics > Endpoints** | Enumerate every IP and MAC address in the capture. Use to detect rogue or unexpected devices. Sort by packet count to find dominant hosts. |
| **Statistics > IO Graph** | Plot throughput over time. Layer a second graph line with an error filter (e.g. `tcp.analysis.retransmission`) to correlate errors with throughput dips. |
| **Statistics > TCP Stream Graphs > RTT** | After following a TCP stream, visualize round-trip latency per packet. Spikes indicate latency at the measured hop. Useful for distinguishing application slowness from network slowness. |
| **Analyze > Expert Information** | Summary of all flagged conditions (retransmissions, zero windows, etc.) grouped by severity. Start here whenever the file contains TCP. |

---

## Expert Information Severity Guide

Expert Information appears under **Analyze > Expert Information** and is also
shown as colored dots next to packets in the main view.

| Severity | Condition | What it means |
|---|---|---|
| **Warning** | `Previous Segment Not Captured` | A gap in sequence numbers -- likely packet loss between capture point and sender, or capture was late starting. |
| **Warning** | `Zero Window` | The receiving end's TCP buffer is full. Sender is stalled waiting for the receiver to drain. Indicates a slow receiver, not network loss. |
| **Note** | `Retransmission` | Sender did not receive an ACK in time and resent the segment. Occasional retransmissions are normal; a high rate signals path loss. |
| **Note** | `Duplicate ACK` | Receiver is signaling a gap in sequence numbers. Three dup ACKs trigger fast retransmit on the sender. |
| **Note** | `Fast Retransmission` | Sender retransmitted within 20 ms of receiving the third dup ACK -- normal congestion-control behavior. |
| **Chat** | `Window Update` | Receiver is advertising a newly opened buffer. Normal recovery after a Zero Window event. |
| **Chat** | `Connection Establish / SYN / SYN-ACK` | Informational -- confirms handshake completed (or did not). |

**Rule of thumb:** A handful of Note-level events in a long capture is normal.
Sustained Warning events or a high Note-event rate (> 1% of segments) warrants
investigation.

---

## TShark CLI Quick Reference

TShark ships with Wireshark. On Windows it is typically at
`C:\Program Files\Wireshark\tshark.exe`. On Linux/macOS it is usually in
`$PATH` as `tshark`.

```bash
# List available interfaces (use the index number or interface name below)
tshark -D

# Live capture on interface 1 (or by name), save to file
tshark -i 1 -w capture.pcap
tshark -i eth0 -w capture.pcap

# Live capture with BPF filter, stop after 500 packets
tshark -i eth0 -f "port 53" -c 500 -w dns.pcap

# Live capture with BPF filter, stop after 60 seconds
tshark -i eth0 -f "host <TARGET-IP>" -a duration:60 -w host.pcap

# Read a saved file and apply a Wireshark display filter
tshark -r capture.pcap -Y "dns.flags.rcode != 0"

# Read a file, display filter, and extract specific fields as CSV
tshark -r capture.pcap -Y "bootp" \
  -T fields \
  -e frame.number \
  -e ip.src \
  -e ip.dst \
  -e bootp.hops \
  -e bootp.ip.relay \
  -e bootp.option.dhcp \
  -E header=y \
  -E separator=,

# Disable name resolution (faster output, shows raw IPs)
tshark -n -r capture.pcap -Y "tcp.flags.reset == 1"

# Disable name resolution on a live capture
tshark -ni eth0 -f "port 53" -w dns.pcap

# Extract all unique IP addresses from a capture
tshark -r capture.pcap -T fields -e ip.src -e ip.dst -n | sort -u

# Pipe a live remote capture from a Linux host into Wireshark (run from Git Bash or WSL)
ssh user@<REMOTE-HOST> "tcpdump -i eth0 -s 0 -U -w - not port 22" \
  | "C:\Program Files\Wireshark\Wireshark.exe" -k -i -
```

---

## Triage Flow

Follow this sequence when opening an unfamiliar capture file:

```
1. Open the .pcap / .pcapng in Wireshark
        |
        v
2. Statistics > Protocol Hierarchy
   - Is the protocol mix what you expect?
   - Unusually high ARP, LLMNR, or STP? -> broadcast storm / loop
   - No application-layer protocol? -> connection never established
        |
        v
3. Statistics > Conversations  (TCP tab)
   - Which host pairs exchanged the most traffic?
   - Any unexpected source or destination IPs?
   - Asymmetric byte counts (large one direction, tiny the other)?
        |
        v
4. Analyze > Expert Information
   - Any Warnings? -> start there (Zero Window, Previous Segment Not Captured)
   - High Note count? -> check Retransmissions and Duplicate ACKs
   - No Expert Info at all? -> may be a non-TCP capture; check Protocol Hierarchy
        |
        v
5. Apply a targeted display filter
   - Narrow to the specific hosts or protocols that are misbehaving
   - Examples:
       ip.addr == <TARGET-IP> and tcp.flags.reset == 1
       bootp and bootp.hops == 0          (relay not working)
       dns.flags.rcode != 0               (DNS errors)
        |
        v
6. Follow the relevant stream
   - Right-click a packet of interest -> Follow -> TCP Stream (or UDP Stream)
   - Read the full application exchange in sequence
   - Look for: error messages, premature FIN/RST, truncated responses
        |
        v
7. (If needed) Multi-file comparison
   - Open the second capture from the opposite end of the path
   - Apply the same display filter and compare:
       Packet present in both? -> crossed the boundary, look elsewhere
       Present in A, absent in B? -> dropped between A and B
```

---

## Common Field Extractions

These `-T fields` one-liners are useful for quick reporting and scripting.

```bash
# DHCP relay audit (who is the relay agent, what hop count?)
tshark -r capture.pcap -Y "bootp" -T fields \
  -e ip.src -e ip.dst -e bootp.hops -e bootp.ip.relay -e bootp.option.dhcp \
  -E header=y

# DNS query/response pairs with response code
tshark -r capture.pcap -Y "dns" -T fields \
  -e frame.time_relative -e ip.src -e ip.dst \
  -e dns.qry.name -e dns.flags.response -e dns.flags.rcode \
  -E header=y

# TCP RST events with direction and port
tshark -r capture.pcap -Y "tcp.flags.reset == 1" -T fields \
  -e frame.time_relative -e ip.src -e tcp.srcport \
  -e ip.dst -e tcp.dstport \
  -E header=y

# Kerberos error codes (for authentication failures)
tshark -r capture.pcap -Y "kerberos.msg_type == 30" -T fields \
  -e frame.time_relative -e ip.src -e ip.dst \
  -e kerberos.msg_type -e kerberos.error_code \
  -E header=y
```
