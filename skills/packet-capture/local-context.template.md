# Packet Capture — Local Context

> **Instructions:** Copy this file to `local-context.md` (it is gitignored) and fill in your
> environment. Replace every `<PLACEHOLDER>` with real values. Never put passwords, keys, or
> secrets in this file — reference your secrets manager instead (see "SSH / Credential notes"
> below).
>
> `local-context.md` is consumed by the `packet-capture` skill so it can suggest the right tool
> (e.g. pktmon vs netsh trace), correct interface names, and accurate capture points without
> asking you every time.

---

## Site subnets / VLANs

```
# List each VLAN/subnet your lab or environment uses.
# Format:  VLAN <ID> (<NAME>):  <SUBNET>/<PREFIX>  gateway <GW-IP>
VLAN <MGMT-VLAN-ID>  (<MGMT-NAME>):    <MGMT-SUBNET>/<PREFIX>    gateway <MGMT-GW>
VLAN <SERVER-VLAN-ID> (<SERVER-NAME>):  <SERVER-SUBNET>/<PREFIX>  gateway <SERVER-GW>
VLAN <CLIENT-VLAN-ID> (<CLIENT-NAME>):  <CLIENT-SUBNET>/<PREFIX>  gateway <CLIENT-GW>
```

---

## Key hosts

> Format: `<ROLE> = <IP>` — one entry per host. Add or remove rows as needed.

```
<PRIMARY-DC>   = <IP>     # Primary domain controller / AD-integrated DNS
<SECONDARY-DC> = <IP>     # Secondary DC (if present)
DNS-PRIMARY    = <IP>     # DNS resolver (often the same as the primary DC)
DHCP           = <IP>     # DHCP server (often co-located with the primary DC)
FILE-SRV       = <IP>     # Primary file server
MGMT-BOX       = <IP>     # Jump host / management workstation
ROUTER         = <IP>     # Default gateway / firewall (MX, pfSense, open-source router, etc.)
```

---

## Windows servers

> The skill uses OS version to choose `pktmon` (Server 2019+) vs `netsh trace` (Server 2016).

```
# Format:  <HOSTNAME>  OS: <Windows version>  Role: <short description>
<SERVER01>   OS: Windows Server 2022    Role: <role>
<SERVER02>   OS: Windows Server 2019    Role: <role>
<SERVER03>   OS: Windows Server 2016    Role: <role>   # use netsh trace (no pktmon)
```

WinRM / PS-Remoting enabled: yes | no  
Admin share path for ETL retrieval: `\\<SERVER>\<CAP-DIR-SHARE>\`

---

## ESXi hosts

```
# Format:  <HOSTNAME>  IP: <MGMT-IP>  SSH: enabled | disabled
<ESXI01>   IP: <IP>   SSH: disabled   # enable for capture; disable when done
<ESXI02>   IP: <IP>   SSH: disabled
```

SSH approach: direct root SSH | key-based via jump host  
Datastore for capture files: `/vmfs/volumes/<DATASTORE-NAME>/`

---

## vCenter / VCSA

```
vCenter FQDN:    <vcenter.example.com>
vCenter IP:      <IP>
Mgmt NIC:        eth0                # confirm with 'ip a' in Photon shell
SSH:             disabled            # enable via VAMI :5480 or ssh.set; disable when done
```

---

## Meraki

```
Org name:        <ORG-NAME>
Primary network: <NETWORK-NAME>
Key device types:
  MX (firewall/router):   <MODEL>   # can't see LAN-to-LAN switched traffic
  MS (switch):            <MODEL>   # use for east-west captures / SPAN
  MR (AP):                <MODEL>   # Intelligent Capture on current firmware
Dashboard URL:   https://dashboard.meraki.com
```

---

## Capture storage directory

```
# Local laptop path where ETL / pcapng / pcap files land (gitignored).
CAP-DIR = <C:\Captures>

# Remote server temp path (cleaned up after scp/Copy-Item):
REMOTE-CAP-DIR = <C:\Captures>     # Windows servers
ESXI-CAP-DIR   = /vmfs/volumes/<DATASTORE-NAME>/captures/
VCSA-CAP-DIR   = /tmp/             # tmpfs — clean up after scp
```

---

## SSH / Credential notes

**NEVER put passwords, private keys, or API tokens in this file.**

- SSH keys: stored in `<~/.ssh/>` and referenced by host in `~/.ssh/config`; or retrieved from
  `<YOUR-SECRETS-MANAGER>` (e.g. HashiCorp Vault, Azure Key Vault, 1Password CLI).
- Windows admin credentials: use `Get-Credential` at session time or pull from your password
  manager. Do not hardcode.
- Meraki API key: stored as environment variable `MERAKI_API_KEY` or in your secrets manager.
- ESXi root password: stored in your secrets manager; never committed.

> If your environment uses a jump host or bastion for SSH access, add the `ProxyJump` config to
> `~/.ssh/config`, not here.
