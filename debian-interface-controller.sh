#!/bin/bash

INTERFACES_FILE="/etc/network/interfaces"

# Get a list of all network interfaces
interfaces=$(ls /sys/class/net)

# Function to display the list and allow the user to select an interface
select_interface() {
    echo "Select the network interface you wish to configure:"
    index=1
    for interface in $interfaces; do
        echo "[$index] $interface"
        index=$((index + 1))
    done

    # Read a single keypress without needing the "Enter" key
    read -n1 -s selection

    if [[ $selection =~ [0-9] && $selection -le $((index - 1)) && $selection -ge 1 ]]; then
        selected_interface=$(echo $interfaces | cut -d ' ' -f $selection)
        echo -e "\nYou selected: $selected_interface"
        configure_interface $selected_interface
    else
        echo -e "\nInvalid selection!"
        select_interface
    fi
}

# Function to configure the selected network interface
configure_interface() {
    interface=$1

    echo "Do you want to use DHCP or Static IP for $interface? (D/S)"
    read -n1 -s ip_type

    case $ip_type in
        [Dd])
            echo -e "\nYou chose DHCP for $interface."
            generate_dhcp_config $interface
            ;;
        [Ss])
            echo -e "\nYou chose Static IP for $interface."
            generate_static_config $interface
            ;;
        *)
            echo -e "\nInvalid selection!"
            configure_interface $interface
            ;;
    esac
}

# Function to generate a DHCP configuration
generate_dhcp_config() {
    interface=$1
    echo -e "\nGenerating DHCP configuration for $interface..."

    # Replace or add (if necessary)
    new_config=$(awk -v iface=$interface '
    BEGIN { found=0; dhcp_block="auto "iface"\niface "iface" inet dhcp" }
    $0 ~ "^iface "iface" inet" {
        if (!found) {
            found=1
            print dhcp_block
        }
    }
    !found { print }
    END { if (!found) print dhcp_block }
    ' $INTERFACES_FILE)

    echo -e "\nNew /etc/network/interfaces configuration:"
    echo "$new_config"
}

# Function to generate Static IP configuration
generate_static_config() {
    interface=$1

    echo "Enter IP address:"
    read ip_address

    echo "Enter Subnet Mask:"
    read netmask

    echo "Enter Gateway:"
    read gateway

    echo -e "\nGenerating Static IP configuration for $interface..."

    # Replace or add the static configuration
    new_config=$(awk -v iface=$interface -v ip=$ip_address -v mask=$netmask -v gw=$gateway '
    BEGIN { found=0; static_block="auto "iface"\niface "iface" inet static\n\taddress "ip"\n\tnetmask "mask"\n\tgateway "gw }
    $0 ~ "^iface "iface" inet" {
        if (!found) {
            found=1
            print static_block
        }
    }
    !found { print }
    END { if (!found) print static_block }
    ' $INTERFACES_FILE)

    echo -e "\nNew /etc/network/interfaces configuration:"
    echo "$new_config"
}

select_interface
