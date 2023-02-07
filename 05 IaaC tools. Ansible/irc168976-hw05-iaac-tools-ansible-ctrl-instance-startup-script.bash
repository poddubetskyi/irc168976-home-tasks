#!/usr/bin/env bash
#
apt update -y
apt install -y debconf-utils
# Setup the control instance as a NAT instance
debconf-set-selections <<IPTABLES_AUTOANSWERS
iptables-persistent     iptables-persistent/autosave_v4 boolean false
iptables-persistent     iptables-persistent/autosave_v6 boolean false
IPTABLES_AUTOANSWERS
apt install -y iptables-persistent
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sysctl -p
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables-save > /etc/iptables/rules.v4
#
# Setup python and ansible
apt install -y python3.9
ln -sf /usr/bin/python3.9 /usr/bin/python3
ln -sf /usr/bin/python3 /usr/bin/python

apt remove -y --purge python3-apt && \
apt install -y python3-apt

apt install -y python3-pip
python3 -m pip install ansible
