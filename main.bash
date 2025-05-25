#!/bin/bash
# This script is used to change the current DNS server to a specified one.
# This script assume that the dns server is set in /etc/resolv.conf

# CONFIG="/etc/dns_servers.conf"
CONFIG=./dns_servers.conf

get_dns_servers() {
    local -n dns_ref=$1  # associative array to hold provider -> DNS lines
    local provider
    local dns_entry

    while IFS= read -r line || [ -n "$line" ]; do
         # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^# ]] && continue

        # If line ends with ":", it's a provider name
        if [[ "$line" =~ :$ ]]; then
            provider="${line%:}"  # remove the colon
            dns_ref["$provider"]=""
        elif [[ "$line" =~ ^nameserver[0-9]+= ]]; then
            dns_entry="${line#*=}"
            dns_ref["$provider"]+="$dns_entry"$'\n'
        fi
    done < $CONFIG    
}

show_dns_servers() {
    local -n dns_ref=$1
    local index=1
    echo "Available DNS servers:"
    for provider in "${!dns_ref[@]}"; do
        echo "$index) $provider:"
        echo -e "${dns_ref[$provider]}"
        ((index++))
    done
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

declare -A dns_map
get_dns_servers dns_map

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
            ;;
        2)
            # Show available DNS servers
            show_dns_servers dns_map
            ;;
        3)
            # Add a new DNS server
            ;;
        4)
            # Remove a DNS server
            ;;
        5)
            # Restore default DNS server
            ;;
        6)
            # Exit the script
            echo "Exiting..."
            break_flag=1
            ;;
        *)
            echo "Invalid choice. Please try again."
            ;;
    esac
done


