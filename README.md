# Forward Port Script

A simple, cross-distribution Bash script to set up basic NAT forwarding and tunnel IP traffic from a public server to a foreign/private server.

## Features

- Supports **Ubuntu**, **Debian**, **AlmaLinux**, **Rocky Linux**, **CentOS**, and **RHEL**
- Enables IP forwarding
- Configures `iptables` NAT rules for TCP/UDP ports
- Installs and persists firewall rules using OS-specific tools
- Easy interactive menu

## Prerequisites

- Run as `root` or using `sudo`
- Internet access for package installation
- Target system must have `iptables`

## Installation & Usage

1. Clone the repository or download the script:

```bash
curl -O https://raw.githubusercontent.com/MrAriaNet/ForwardPort/main/ForwardPort.sh
chmod +x ForwardPort.sh
sudo ./ForwardPort.sh
````

2. Choose the appropriate option from the menu:

   * `1`: Setup the tunnel and forward ports
   * `2`: Remove all NAT/firewall rules
   * `3`: View current iptables NAT rules
   * `4`: Exit

## Default Forwarded Ports

* `810` TCP & UDP
* `4143` TCP & UDP
* `22` TCP
* All forwarded to the foreign VPS IP entered during setup

## Notes

* On RHEL-based distributions with `firewalld` enabled, consider using `firewall-cmd` for persistent configuration or disable `firewalld`.
* The script saves rules to:

  * `/etc/iptables/rules.v4` and `rules.v6` on Ubuntu/Debian
  * `/etc/sysconfig/iptables` on RHEL-based systems

## License

MIT License
