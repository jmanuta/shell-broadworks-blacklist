#!/usr/bin/env bash
# jmanuta@bluip.com | 2018.02.01
# Description:  This will discover the XSP IP address, then run the expect script to
#               add the specified IP address to the XSP blacklist.



# Set variables
scriptPath="/export/home/bwadmin/jmscripts"
serverIp=$(cat /etc/sysconfig/network-scripts/ifcfg-eth0 | grep IPADDR | cut -d'=' -f2)
logFile="${scriptPath}/blacklist.log"
option=$1
blockIp=$2

# Display usage
usage() {
	if [ -z "$1" ]; then
    		(
    		echo -e "\nDescription:\tAdd or delete a blacklist IP or show current list"
    		echo -e "Usage:\t\t$(basename $0) [option] [ip-address]"
		echo -e "Options:\tadd \tAdd an IP to blacklist"
		echo -e "\t\tdelete \tDelete an IP from blacklist"
		echo -e "\t\tshow \tShow current blacklist\n"
    		) 1>&2
    		exit
	fi
}


# Add, Delete or Show
action() {
	if [ "$1" = "add" ]; then
		shift
    		expectOutput=$(${scriptPath}/blacklist-add.exp $1 ${serverIp})
    		if [[ $expectOutput = *"...Done"* ]]; then
        		echo -e "\nSuccessful\n"
                        echo -e "$(date) -- ADD\n" >> ${logFile}
                        echo "$expectOutput" >> ${logFile}
                        echo -e "\n\n" >> ${logFile}
    		elif [[ $expectOutput = *"entry is already present in list"* ]]; then
        		echo -e "\n$1 was already added\n"
    		else
        		echo -e "$(date) -- ADD\n" >> ${logFile} 
        		echo "$expectOutput" >> ${logFile}
        		echo -e "\n\n" >> ${logFile}
        		echo -e "\nEncountered error\n"
    		fi
	elif [ "$1" = "show" ]; then
		expectOutput=$(${scriptPath}/blacklist-show.exp)
		if [[ $expectOutput = *"TCP"* ]]; then
			echo
        		printf "%32s %14s %10s\n" "Source IP/Mask" "Port Range" "Protocol"
                	echo "==========================================================="
    			echo -e "\n${expectOutput}\n" |\
    			grep TCP |\
    			awk '{printf "%32s %14s %10s\n", $1, $3, $4}'
			echo
    		else
        		echo -e "\nNo entries found\n"
    		fi
        elif [ "$1" = "delete" ]; then
		shift
                expectOutput=$(${scriptPath}/blacklist-delete.exp $1 ${serverIp})
                if [[ $expectOutput = *"...Done"* ]]; then
                        echo -e "\nSuccessful\n"
                        echo -e "$(date) -- DELETE\n" >> ${logFile}
                        echo "$expectOutput" >> ${logFile}
                        echo -e "\n\n" >> ${logFile}
		elif [[ $expectOutput = *"Entry not found"* ]]; then
			echo -e "\nError: $1 was not found in blacklist\n"
                else
                        echo -e "$(date) -- DELETE\n" >> ${logFile}
                        echo "$expectOutput" >> ${logFile}
                        echo -e "\n\n" >> ${logFile}
                        echo -e "\nEncountered error\n"
		fi
	else
		echo -e "\n% Invalid option %"
		usage
	fi
}

# Main
usage ${option}
action ${option} ${blockIp}

