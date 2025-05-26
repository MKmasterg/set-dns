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

validate_dns() {
    local -n is_valid_ref=$1
    local nameserver1="$2"
    local nameserver2="$3"
    if ! [[ -z "$nameserver2" ]]; then
        if ! [[ "$nameserver1" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || ! [[ "$nameserver2" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Invalid DNS server format. Please use the format x.x.x.x"
        is_valid_ref=0
        fi
    else
        if ! [[ "$nameserver1" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Invalid DNS server format. Please use the format x.x.x.x"
        is_valid_ref=0
        fi
    fi
}

change_dns_server() {
    local nameserver1="$1"
    local nameserver2="$2"
    local resolv_conf="/etc/resolv.conf"
    
    # Validate the dns servers
    local validation=1
    validate_dns validation "$nameserver1" "$nameserver2"
    if ! [ "$validation" -eq 1 ]; then
    return
    fi
    # Write the new DNS servers to /etc/resolv.conf
    {
        echo "nameserver $nameserver1"
        if ! [[ -z "$nameserver2" ]]; then
            echo "nameserver $nameserver2"
        fi
    } >| "$resolv_conf"
}

add_dns_server() {
    local provider="$1"
    local nameserver1="$2"
    local nameserver2="$3"

    {
        echo
        echo "$provider:"
        echo "nameserver1=$nameserver1"
        if ! [[ -z "$nameserver2" ]]; then
            echo "nameserver2=$nameserver2"
        fi
    } >> "$CONFIG"

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
dns_choice=0

# Fisrt check if there is a backup of the resolv.conf file
if [ ! -f /etc/resolv.conf.bak ]; then
    echo "There is no backup of the resolv.conf file."
    read -p "Do you want to create a backup? (Y/n): " create_backup
    create_backup=${create_backup:-y}
    if [[ "$create_backup" =~ ^[Yy]$ ]]; then
        echo "Creating a backup of the current resolv.conf file..."
        cp /etc/resolv.conf /etc/resolv.conf.bak
    else
        echo "Backup not created. The script will continue without a backup."
    fi
else
    echo "Backup of resolv.conf already exists."
fi

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
    clear
    case $user_choice_task in
        1)
            # Change DNS server
            echo "Please select a DNS server to change to:"
            show_dns_servers dns_map
            read -p "Enter the number of the DNS server you want to use: " dns_choice
            # Validate the choice
            if ! [[ "$dns_choice" =~ ^[0-9]+$ ]] || [ "$dns_choice" -lt 1 ] || [ "$dns_choice" -gt "${#dns_map[@]}" ]; then
                echo "Invalid choice. Please try again."
                continue
            fi
            # Get the selected DNS server
            # Keys are providers, values are DNS entries so it needs to get the key by iteration
            index=1
            for provider in "${!dns_map[@]}"; do
                if [ "$index" -eq "$dns_choice" ]; then
                    selected_provider="$provider"
                    break
                fi
                ((index++))
            done

            # Get the DNS entries for the selected provider
            dns_entries="${dns_map[$selected_provider]}"
            # Split the entries into an array
            IFS=$'\n' read -r -d '' -a dns_array <<< "$dns_entries"
            # Get the first two DNS servers
            dns_server1="${dns_array[0]}"
            dns_server2="${dns_array[1]}"
            # Change the DNS server
            change_dns_server "$dns_server1" "$dns_server2"
            echo "DNS server changed to $dns_server1 and $dns_server2"
            ;;
        2)
            # Show available DNS servers
            show_dns_servers dns_map
            ;;
        3)
            # Add a new DNS server
            provider=""
            while [ -z "$provider" ]; do
                read -p "Please enter the name of provider: " provider
            done
            read -p "Please enter the first nameserver: " nameserver1
            read -p "Please enter the second nameserver: " nameserver2
            # Input validation
            while [ -z "$nameserver1" ]; do
                echo "First nameserver cannot be empty"
                read -p "Please enter the first nameserver: " nameserver1
            done
            # DNS validation
            validation=1
            validate_dns validation "$nameserver1" "$nameserver2"
            if ! [ "$validation" -eq 1 ]; then
                continue
            fi
            add_dns_server "$provider" "$nameserver1" "$nameserver2"
            get_dns_servers dns_map
            
            echo "Done!"
            ;;
        4)
            # Remove a DNS server
            echo "Please select a DNS server to remove:"
            show_dns_servers dns_map
            read -p "Enter the number of the DNS server you want to remove: " dns_choice
            # Validate the choice
            if ! [[ "$dns_choice" =~ ^[0-9]+$ ]] || [ "$dns_choice" -lt 1 ] || [ "$dns_choice" -gt "${#dns_map[@]}" ]; then
                echo "Invalid choice. Please try again."
                continue
            fi
            # Get the selected DNS server
            index=1
            for provider in "${!dns_map[@]}"; do
                if [ "$index" -eq "$dns_choice" ]; then
                    selected_provider="$provider"
                    break
                fi
                ((index++))
            done
            # Remove the selected DNS server from the configuration file
            sed -i "/^$selected_provider:/,/^$/d" "$CONFIG"

            unset dns_map
            declare -A dns_map
            get_dns_servers dns_map
            echo "DNS server $selected_provider removed successfully."
            ;;
        5)
            # Restore default DNS server
            echo "Restoring default DNS server..."
            if [ -f /etc/resolv.conf.bak ]; then
                cp /etc/resolv.conf.bak /etc/resolv.conf
                echo "Default DNS server restored."
            else
                echo "No backup found. Cannot restore default DNS server."
            fi
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


