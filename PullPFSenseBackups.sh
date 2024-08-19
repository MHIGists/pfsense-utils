#!/bin/bash

# specify username and password
username="username"
password="password"

# specify the file containing the IP addresses
ip_file="ip_addresses.txt"

# specify the remote directory to copy
remote_dir="/conf/backup"

# specify the base directory for storing backups
base_dir="$HOME/backups"

# specify the log file for storing problematic IPs
log_file="$HOME/illegal_option_log.txt"

error_log="$HOME/debug_log.txt"
echo $base_dir
# create the base directory if it doesn't exist
mkdir -p "$base_dir"

# loop through each IP address in the file
while IFS= read -r ip
do
    echo "Processing IP: $ip"
    
    ip_dir="$base_dir/$ip"
    mkdir -p "$ip_dir"

    start_time=$(date +%s)

    # use sshpass to login and copy the directory, capture any error message
    error_message=$( { timeout 5 sshpass -p "$password" scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -r "$username@$ip:$remote_dir" "$ip_dir/" ; } 2>&1 )

    # calculate and print the elapsed time
    end_time=$(date +%s)
    elapsed_time=$((end_time - start_time))
    echo "Elapsed time for IP $ip: $elapsed_time seconds"

    if [[ $error_message == *"Illegal option -r"* ]] || [[ $error_message == *"Their offer: ssh-dss,ssh-rsa"* ]]; then
        echo "$ip $error_message" >> "$log_file"
    fi
    echo "$error_message" >> "$error_log"
    if [ $? -eq 124 ]; then
        echo "Timeout occurred for IP: $ip"
    fi
done < "$ip_file"
