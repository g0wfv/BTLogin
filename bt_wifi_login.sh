#!/bin/sh 

# bt_wifi_login.sh - A simple shell script to automate BT Wi-Fi logins.
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program. If not, see http://www.gnu.org/licenses/.

user="<BT ID or Email>"
pass="<BT Password>"
homeURL="https://www.btwifi.com:8443/home"
logonURL="https://www.btwifi.com:8443/tbbLogon"
DNServer="8.8.8.8"

# parse command line arguments passed to the script.
parseCommandLine() {
    while [ $# -gt 0 ]; do
        case $1 in
        -h | --help)
            cat <<EOF
$processName - A simple shell script to automate BT Wi-Fi logins.
Copyright (C) 2017, 2018 Tony Corbett, G0WFV

Usage:
$processName [-h|--help] [-s|--syslog] [-t|--timeout n] [-d|--debug] [wait]

Options:
-h --help         Display this help
-s --syslog       Log result to syslog
-t n --timeout n  Wait n seconds for a reply [default 30]
-d --debug        Enable debug logging
wait              An integer value to wait between checks.
                  The script will loop continuously checking your login
                  status. Without it, the script will check once and
                  terminate.

EOF
            exit 0
            ;;

        -s | --syslog)
            syslog=true
            shift
            ;;

        -t | --timeout)
            timeout=$2
            shift
            shift
            ;;

        -d | --debug)
            debug=true
            shift
            ;;

        *)
            if [ $1 -ge 1 ] 2>/dev/null && [ $1 -gt 0 ]; then
                sleepTime=$1
            fi
            shift
            ;;
        esac
    done
}

# This function checks if the device is connected to a BT Wi-fi hotspot.
# It uses the iwinfo command to get information about the available 
# wireless networks and greps for "BTWi-fi" in the output.
# If "BTWi-fi" is found, it means that the device is connected to a 
# BT Wi-fi hotspot, and the function returns 0.
# If "BTWi-fi" is not found, it means that the device is not connected 
# to a BT Wi-fi hotspot, and the function returns 4.
# The function also has optional debug and syslog flags to print messages
# to the console or log messages to the system logger.
hasBTWiFi() {
    myssid=$(iwinfo | grep "BTWi-fi")
    if [ -n "$myssid" ]; then
        [ $debug ] && echo "Connected to BT Wi-fi hotspot."
        [ $debug ] && [ $syslog ] && /usr/bin/logger -t "$processName[$pid]" "Connected to BT Wi-fi hotspot."
        return 0
    else
        [ $debug ] && echo "NOT Connected to BT Wi-fi hotspot."
        [ $syslog ] && /usr/bin/logger -t "$processName[$pid]" "NOT Connected to BT Wi-fi hotspot."
        return 4
    fi
}

# This function checks the internet connectivity by pinging a DNS server.
# It uses the ping command with options -W 1 (to wait for 1 second for a response) 
# and -c 1 (to send only one packet).
# If the ping is successful, it returns 0, indicating that there is internet connectivity.
# Otherwise, it returns 4, indicating that there is no internet connectivity.
checkConnection() {
    pkLoss="$(ping -W 1 -c 1 ${DNServer} >/dev/null 2>&1 && echo OK || echo NOK)"
    [ $debug ] && echo "Pinging IP: ${DNServer}"
    timeispk="$(date +%T)"
    if [ "$pkLoss" = "OK" ]; then
        [ $debug ] && echo "@ TIME - $timeispk: 0% Packet Loss --> CONNECTION OK"
        [ $debug ] && [ $syslog ] && /usr/bin/logger -t "$processName[$pid]" "CONNECTION OK"
        return 0
    else
        [ $debug ] && echo "@ TIME - $timeispk: 100% Packet Loss --> NO CONNECTION"
        [ $syslog ] && /usr/bin/logger -t "$processName[$pid]" "NO CONNECTION"
        return 4
    fi
}

# This is a function called "checkLoginServer" that is intended to test the 
# connection to the BT Wi-Fi login server and determine if the user is already logged in.
checkLoginServer() {
    [ $debug ] && echo "Test connection to BT Wi-Fi login server."
    foo=$(curl -s "$homeURL" --insecure --connect-timeout $timeout)
    rc=$?

    if [ $rc -eq 6 ]; then
        [ $debug ] && echo "DNS can't resolve BT Wi-Fi login server address."
        [ $syslog ] && /usr/bin/logger -t "$processName[$pid]" "DNS can't resolve BT Wi-Fi login server address."
        return 6
    fi

    if [ $rc -ne 0 ]; then
        [ $debug ] && echo "No reply from the BT Wi-fi login server."
        [ $syslog ] && /usr/bin/logger -t "$processName[$pid]" "No reply from the BT Wi-fi login server."
        return 6
    fi

    if [ echo "$foo" | grep -q 'You may have lost your connection to the BTWiFi signal' ]; then
        [ $debug ] && echo "Not connected to a BT Wi-fi hotspot."
        [ $syslog ] && /usr/bin/logger -t "$processName[$pid]" "Not connected to a BT Wi-fi hotspot."
        return 6
    fi

    if [ echo "$foo" | grep -q 'now logged in with BT Wi-fi' ]; then
        [ $debug ] && echo "Already logged in. Nowt to do!"
        [ $debug ] && [ $syslog ] && /usr/bin/logger -t "$processName[$pid]" "Already logged in. Nowt to do!"
        return 0
    fi

    [ $debug ] && echo "BT Wi-Fi login server available"
    [ $debug ] && [ $syslog ] && /usr/bin/logger -t "$processName[$pid]" "BT Wi-Fi login server available"
    return 1
}

# This is a function called "doLogin" that attempts to log on to the BT Wi-Fi network using 
# the specified credentials.
# The function uses curl to send a POST request to the "$logonURL" variable with the 
# specified username and password values. The "--data-urlencode" flag is used to encode 
# the values as URL-encoded strings. The response from the server is stored in the "foo" variable. 
# The "--insecure" flag is used to disable SSL certificate validation, and 
# the "--connect-timeout" flag sets the maximum time allowed for the connection attempt.
doLogin() {
    [ $debug ] && echo "Attempting log on to BT Wi-Fi... "
    [ $syslog ] && /usr/bin/logger -t "$processName[$pid]" "Attempting log on to BT Wi-Fi... "
    foo=$(curl -s "$logonURL" \
        --data-urlencode "username=$user" \
        --data-urlencode "password=$pass" \
        --insecure --connect-timeout $timeout)

    ONLINE=$(curl -s "$homeURL" --insecure --connect-timeout $timeout 2>/dev/null | grep "now logged in")

    if [ $? -eq 0 ]; then
        [ $debug ] && echo "Success! You're online with BT Wi-Fi."
        [ $syslog ] && /usr/bin/logger -t "$processName[$pid]" "Success! You're online with BT Wi-Fi."
        return 0
    else
        [ $debug ] && echo "Fail! Couldn't logon to BT Wi-Fi."
        [ $syslog ] && /usr/bin/logger -t "$processName[$pid]" "Fail! Couldn't logon to BT Wi-Fi."
        return 4
    fi
}

# This is a function called "doRestartWWAN" that restarts the WWAN (Wireless Wide Area Network) 
# interface for the BT Wi-Fi network.
# The first line of the function uses the "uci" command to retrieve the 
# UCI (Unified Configuration Interface) settings for the wireless network, 
# filters out the line containing "BTWi-fi", and extracts the first two fields separated by a dot. 
# This value is then assigned to the "uci" variable.
# The second line uses the "uci" command to set the "disabled" flag for the specified 
# UCI configuration to 1, effectively disabling the wireless network.
doRestartWWAN() {
    uci=$(uci show wireless | grep "BTWi-fi" | cut -d '.' -f 1,2)
    uci -q set ${uci}.disabled=1
    [ $debug ] && echo "Force restart of WWAN interface for BT Wi-Fi."
    [ $syslog ] && /usr/bin/logger -t "$processName[$pid]" "Force restart of WWAN interface for BT Wi-Fi."
    sleep 5
}

# Orchestrate the login process
doBTWiFi() {
    # test internet connection, return if OK
    checkConnection && return 0

    # test BT Wi-Fi login server if connected
    checkLoginServer
    rc=$?

    # restart WWAN interface if can't connect to BT Wi-Fi login server
    if [ $rc -eq 6 ]; then
        doRestartWWAN
    fi

    # try login if connected to BT Wi-Fi hotspot but no internet
    if [ $rc -ne 0 ]; then
        doLogin
    fi
}

# Main script routine
processName=$(basename "$0")
pid=$$

sleepTime=0
timeout=30

parseCommandLine "$@"

# Loop to continuously try to login ...
loop=true
while $loop; do
    # are we connected to a BT Wi-Fi hotspot?
    hasBTWiFi

    # BT Wi-Fi login process
    if [ $? -eq 0 ]; then
        doBTWiFi
    fi

    # wait to try again
    if [ $sleepTime -ge 1 ]; then
        [ $debug ] && echo "Checking again in $sleepTime seconds ..."
        [ $debug ] && [ $syslog ] && /usr/bin/logger -t "$processName[$pid]" "Checking again in $sleepTime seconds ..."
        sleep $sleepTime
    else
        loop=false
    fi
done

[ $debug ] && echo "Exited $processName[$pid]!"
[ $syslog ] && /usr/bin/logger -t "$processName[$pid]" "Exited $processName[$pid]!"
