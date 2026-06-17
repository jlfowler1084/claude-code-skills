# packet-capture

A portable agent skill for capturing network packets without installing software on remote hosts,
then analyzing the captures locally in Wireshark. Covers Windows (pktmon on Server 2019+/Win10
1809+, netsh trace on Server 2016), VMware ESXi/vCenter (pktcap-uw, tcpdump-uw, VCSA tcpdump),
and Cisco Meraki (Dashboard capture, MS port mirror / SPAN). All environment-specific details
(IPs, hostnames, VLAN IDs) stay in a gitignored `local-context.md`; this skill ships with a
generic `local-context.template.md` that every user fills in for their own site.

---

## Sources

**Windows**
- [pktmon command reference](https://learn.microsoft.com/windows-server/administration/windows-commands/pktmon)
- [pktmon start](https://learn.microsoft.com/windows-server/administration/windows-commands/pktmon-start)
- [pktmon etl2pcap](https://learn.microsoft.com/windows-server/administration/windows-commands/pktmon-etl2pcap)
- [pktmon filter add](https://learn.microsoft.com/windows-server/administration/windows-commands/pktmon-filter-add)
- [Packet Monitor overview](https://learn.microsoft.com/windows-server/networking/technologies/pktmon/pktmon)
- [netsh trace](https://learn.microsoft.com/windows-server/administration/windows-commands/netsh-trace)
- [Using Netsh to manage traces](https://learn.microsoft.com/windows/win32/ndf/using-netsh-to-manage-traces)
- [microsoft/etl2pcapng (GitHub releases)](https://github.com/microsoft/etl2pcapng)

**VMware ESXi / vCenter**
- [pktcap-uw command syntax (vSphere 8.0)](https://techdocs.broadcom.com/us/en/vmware-cis/vsphere/vsphere/8-0/vsphere-networking/monitoring-network-packets/using-the-pktcap-uw-tool/pktcap-uw-command-syntax.html)
- [pktcap-uw general options / snaplen 0](https://techdocs.broadcom.com/us/en/vmware-cis/vsphere/vsphere/8-0/vsphere-networking/monitoring-network-packets/using-the-pktcap-uw-tool/general-options-for-capturing-and-tracing-packets.html)
- [Broadcom KB 341568 — pktcap-uw uplink/switchport + kill recipe](https://knowledge.broadcom.com/external/article/341568/using-the-pktcapuw-tool-in-esxi-55-and-l.html)
- [Enable SSH from the vSphere Client](https://techdocs.broadcom.com/us/en/vmware-cis/vsphere/vsphere-sdks-tools/8-0/getting-started-with-esxcli-8-0/running-host-management-commands-in-the-esxi-shell/remote-esxi-shell-access-with-ssh/enable-ssh-from-the-vsphere-client.html)
- [Broadcom KB 421448 — Enable SSH on vCenter via VAMI](https://knowledge.broadcom.com/external/article/421448/how-to-enable-ssh-service-on-vcenter-ser.html)
- [Broadcom KB 322847 — tcpdump on VCSA](https://knowledge.broadcom.com/external/article/322847/troubleshooting-tools-for-networking-on.html)
- [Wireshark sshdump extcap](https://www.wireshark.org/docs/man-pages/sshdump.html)

**Cisco Meraki**
- [Packet Capture Overview](https://documentation.meraki.com/Platform_Management/Dashboard_Administration/Troubleshooting_and_Support/Troubleshooting/Packet_Capture_Overview)
- [Getting Started with Wireshark (Meraki)](https://documentation.meraki.com/Platform_Management/Dashboard_Administration/Troubleshooting_and_Support/Troubleshooting/Getting_started_on_Packet_Captures_with_Wireshark)
- [MS Packet Captures & Port Mirroring](https://documentation.meraki.com/Switching/MS_-_Switches/Operate_and_Maintain/Monitoring_and_Reporting/Packet_Captures_and_Port_Mirroring_on_the_MS_Switch)
- [Traffic Mirroring (RSPAN)](https://documentation.meraki.com/Switching/MS_-_Switches/Operate_and_Maintain/Monitoring_and_Reporting/Traffic_Mirroring)

**Agent skill infrastructure**
- [Claude Code skills](https://code.claude.com/docs/en/skills)
- [Codex skills](https://developers.openai.com/codex/skills)
- [Gemini CLI skills](https://geminicli.com/docs/cli/skills/)
- [Qwen Code skills](https://qwenlm.github.io/qwen-code-docs/en/users/features/skills/)

---

## Validation

Passes `ClaudeInfra Test-SkillCompliance.ps1` with no errors. Ships 5 manual scenario evals
covering the key platform branches (Server 2022 pktmon, Server 2016 netsh trace, ESXi uplink,
VCSA tcpdump, Meraki east-west / MS switch).

---

## Examples

**pktmon — capture and convert on a Windows Server 2022 host:**
```powershell
pktmon filter add -p 80; pktmon start --capture --pkt-size 0 --comp nics --file-name C:\Captures\cap.etl; <reproduce>; pktmon stop; pktmon etl2pcap C:\Captures\cap.etl --out C:\Captures\cap.pcapng
```

**ESXi — live pipe to Wireshark over SSH (from Git Bash/WSL):**
```bash
ssh root@<ESXI-HOST> "pktcap-uw --uplink <vmnicX> --capture UplinkSndKernel,UplinkRcvKernel -s 0 -c 500 -o -" | "C:\Program Files\Wireshark\Wireshark.exe" -k -i -
```

**Meraki — download a .pcap from the Dashboard:**
```
Dashboard > Network-wide > Monitor > Packet capture
  > select MS switch and interface > set Output = "Download .pcap file (for Wireshark)" > Start
```
