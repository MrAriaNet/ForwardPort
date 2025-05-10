#!/bin/bash

# Must run as root
if [[ $EUID -ne 0 ]]; then
    echo "Please run this script as root"
    exit 1
fi

# Detect Linux distribution
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    distro=$(echo "$ID" | tr '[:upper:]' '[:lower:]')
else
    echo "Unable to detect distribution"
    exit 1
fi

# Set package manager and firewall save methods
case "$distro" in
    ubuntu|debian)
        pkg_update="apt update -y"
        pkg_upgrade="apt upgrade -y"
        pkg_install="apt install -y iptables-persistent"
        firewall_save="netfilter-persistent save"
        rules_v4="/etc/iptables/rules.v4"
        rules_v6="/etc/iptables/rules.v6"
        ;;
    almalinux|rocky|centos|rhel)
        pkg_update="dnf update -y"
        pkg_upgrade=""
        pkg_install="dnf install -y iptables iptables-services"
        firewall_save="service iptables save"
        rules_v4="/etc/sysconfig/iptables"
        rules_v6="/etc/sysconfig/ip6tables"
        ;;
    *)
        echo "Unsupported distribution: $distro"
        exit 1
        ;;
esac

# Get IP address and default interface
thisServerIP=$(ip a | awk '/inet / && !/127.0.0.1/ { sub(/\/.*/, "", $2); print $2; exit }')
networkInterfaceName=$(ip -o -4 route show to default | awk '{print $5}')

# Show menu
echo "Select an option:"
echo "  1) Setup tunnel"
echo "  2) Remove tunnel rules"
echo "  3) View current NAT rules"
echo "  4) Exit"
read -rp "Enter your choice [1-4]: " OPTION

case "$OPTION" in
1)
    echo "Enabling IP forwarding..."
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    sysctl -p

    echo "Adding iptables NAT rules..."
    iptables -t nat -I PREROUTING -p tcp --dport 810 -j DNAT --to-destination "$thisServerIP"
    iptables -t nat -I PREROUTING -p udp --dport 810 -j DNAT --to-destination "$thisServerIP"
    iptables -t nat -I PREROUTING -p tcp --dport 4143 -j DNAT --to-destination "$thisServerIP"
    iptables -t nat -I PREROUTING -p udp --dport 4143 -j DNAT --to-destination "$thisServerIP"
    iptables -t nat -I PREROUTING -p tcp --dport 22 -j DNAT --to-destination "$thisServerIP"

    echo "Enter the foreign server IP to forward traffic to:"
    read -r foreignVPSIP
    iptables -t nat -A PREROUTING -j DNAT --to-destination "$foreignVPSIP"
    iptables -t nat -A POSTROUTING -o "$networkInterfaceName" -j MASQUERADE

    echo "Installing required packages and saving rules..."
    eval "$pkg_update"
    eval "$pkg_upgrade"
    eval "$pkg_install"

    # Firewalld check
    if systemctl is-active --quiet firewalld; then
        echo "Note: firewalld is active. You may also need to use firewall-cmd if iptables rules do not persist."
    fi

    iptables-save > "$rules_v4"
    ip6tables-save > "$rules_v6" 2>/dev/null || true
    eval "$firewall_save" || true

    echo "Tunnel setup is complete."
    ;;

2)
    echo "Flushing NAT and firewall rules..."
    iptables -t nat -F
    iptables -F
    ip6tables -F
    echo "All rules removed."
    ;;

3)
    echo "Displaying current NAT rules:"
    iptables -t nat -L -n --line-numbers
    ;;

4)
    echo "Exiting."
    exit 0
    ;;

*)
    echo "Invalid option."
    ;;
esac
