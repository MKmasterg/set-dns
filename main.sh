#!/bin/bash
# This script is used to change the current DNS server to a specified one.
# This script assume that the dns server is set in /etc/resolv.conf

# CONFIG="/etc/dns_servers.conf"
CONFIG=./dns_servers.conf

get_dns_servers() {
    local dns_servers=()
    local counter=0
    while IFS= read -r line; do

        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^# ]] && continue # Only non-empty, non-comment lines will be processed
        
        # Add the DNS server to the array
        dns_servers+=("$counter" "$line")
        ((counter++))
    done < "$CONFIG"
    echo "${dns_servers[@]}"
}

# Check if the user has privileges to change the DNS server
if (( $EUID != 0 )); then
  echo "You must be root to change the DNS server."
  exit 1
fi

# Load the custom DNS servers from the configuration file
# Check if the configuration file exists
if [ ! -f $CONFIG ]; then
  echo "Configuration file $CONFIG not found."
  exit 1
fi

break_flag=0
user_choice_task=0

# Asks the user to select a choice to perform a task
while [ $break_flag -eq 0 ]; do
    echo "Please select a task to perform:"
    echo "1. Change DNS server"
    echo "2. Show available DNS servers"
    echo "3. Add a new DNS server"
    echo "4. Remove a DNS server"
    echo "5. restore default DNS server"
    echo "6. Exit"
    read -p "Enter your choice (1-6): " user_choice_task
    case $user_choice_task in
        1)
            # Change DNS server
        
        2)
            # Show available DNS servers
            
        3)
            # Add a new DNS server
        4)
            # Remove a DNS server
        5)
            # Restore default DNS server
        6)
            # Exit the script
            echo "Exiting..."
            break_flag=1
            ;;
        *)
            echo "Invalid choice. Please try again."
            ;;


