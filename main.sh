#!/bin/bash
# This script is used to change the current DNS server to a specified one.
# This script assume that the dns server is set in /etc/resolv.conf

# Check if the user has privileges to change the DNS server
if (( $EUID != 0 )); then
  echo "You must be root to change the DNS server."
  exit 1
fi

# Load the custom DNS servers from the configuration file
# Check if the configuration file exists
if [ ! -f /etc/dns_servers.conf ]; then
  echo "Configuration file /etc/dns_servers.conf not found."
  exit 1
fi
# Read the DNS servers from the configuration file

