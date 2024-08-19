#!/bin/bash

# specify username and password
username="username"
password="password"

remote_command="cat /etc/version && hostname"

# specify the file to store the IP addresses and hostnames grouped by version
output_file="hosts_by_version.txt"
hostnames_file="hostnames.txt"

# create an associative array to store IP addresses and hostnames by version
declare -A hosts_by_version

# create an array to store skipped IPs
declare -a skipped_ips

# loop through each IP address in the range
for ((x=1; x<=254; x++))
do
    for ((j=131; j<=132; j++))
    do
		# set up according to your networks
        ip="10.$j.$x.1"
        echo "Processing IP: $ip"

        if sshpass -p "$password" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=3 "$username@$ip" "exit" >/dev/null 2>&1; then
            # use timeout command to limit the execution time of the remote command
            result=$(sshpass -p "$password" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$username@$ip" "timeout 3 $remote_command" 2>/dev/null)
            IFS=$'\n' read -r -a parts <<< "$result"
            version="${parts[0]}"
            hostname="${parts[1]}"

            if [ -n "$version" ]; then
                hosts_by_version["$version"]+=" $ip => $hostname"
            else
                echo "Skipping IP: $ip (Version retrieval timeout)"
                skipped_ips+=("$ip")
            fi
        else
            echo "Skipping IP: $ip (Connection timeout)"
            skipped_ips+=("$ip")
        fi
    done
done

# write the IP addresses and hostnames grouped by version to the output file
> "$output_file"
for version in "${!hosts_by_version[@]}"
do
    echo "Version: $version" >> "$output_file"
    echo "${hosts_by_version[$version]}" >> "$output_file"
    echo >> "$output_file"
done

# write skipped IP addresses and their hostnames to hostnames file
> "$hostnames_file"
for ip in "${skipped_ips[@]}"
do
    hostname=$(sshpass -p "$password" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$username@$ip" "hostname" 2>/dev/null)
    echo "IP: $ip => Hostname: $hostname" >> "$hostnames_file"
done

echo "Hosts grouped by version have been saved to $output_file."
echo "Skipped IPs and their hostnames have been saved to $hostnames_file."
