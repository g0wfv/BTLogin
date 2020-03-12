#! /bin/sh

# bt_login.sh - A simple shell script to automate BT Wifi and
# BTWifi-with-FON hotspot logins.
# Copyright (C) 2017, 2018  Tony Corbett, G0WFV

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# logout_url=https://www.btwifi.com:8443/accountLogoff/home?confirmed=true

# SET YOUR USERNAME, PASSWORD, AND TYPE OF BT CONNECTION HERE
user=name@domain.com
pass=PaSsWoRd
BT_type='BTWifi-with-Fon'
# BT_type='BT Wifi'

parseCommandLine()
{
	# Parse command line arguments ...
	while [ $# -gt 0 ]; do
		case $1 in
			-h|--help)
				cat << EOF
$processName - A simple shell script to automate BT Wifi and BTWifi-with-FON hotspot logins.
Copyright (C) 2017, 2018  Tony Corbett, G0WFV

Usage:
    $processName [-h|--help] [-s|--syslog] [-t|--timeout n] [wait]

Options:
    -h      --help         Display this help
    -s      --syslog       Log result to syslog
    -t n    --timeout n    Wait n seconds for a reply [default 30]
    wait                   An integer value to wait between checks.
                           The script will loop continuously checking your login
                           status. Without it, the script will check once and
                           terminate.

EOF
				exit 0
			;;

			-s|--syslog)
				syslog=true
				shift
			;;

			-t|--timeout)
				timeout=$2
				shift
				shift
			;;

			*)
				if [ $1 -ge 1 2>/dev/null ] && [ $1 -gt 0 ]; then
					sleepTime=$1
				fi
				shift
			;;
		esac
	done
}

doLogin()
{
	response=$(/usr/bin/wget https://192.168.23.21:8443/home --no-check-certificate --timeout=$timeout --tries=1 -O - -o /dev/null)

	if [ $? -ne 0 ]; then
		[ $syslog ] && /usr/bin/logger -t $processName[$pid] "No reply from the $BT_type login server."
		return 1
	fi

	# How does this work? Surely if the connection is lost there would be no response.
	bar=$(echo $response | /bin/grep 'You may have lost your connection to the BTWifi signal')
	# || bar=$(echo $response | /bin/grep 'Having trouble logging in?')

	if [ $? -eq 0 ]; then
		[ $syslog ] && /usr/bin/logger -t $processName[$pid] "Not connected to a $BT_type hotspot."
		return 2
	fi

	# TODO: Is it really "logged in to BT Wi-fi" on one and "logged on to Wi-Fi" on the other? (Note: 'in' vs 'on' and 'Wi-fi' vs 'Wi-Fi')
	bar=$(echo $response | /bin/grep 'now logged in to BT Wi-fi') || bar=$(echo $response | /bin/grep 'now logged on to BT Wi-Fi')

	if [ $? -eq 0 ]; then
		[ $syslog ] && /usr/bin/logger -t $processName[$pid] "Already logged in. Nowt to do!"
		return 3
	fi

	[ $syslog ] && /usr/bin/logger -t $processName[$pid] "Attempting to log in to $BT_type ... "

	if [ "$BT_type" = 'BTWifi-with-Fon' ]; then
		response=$(/usr/bin/wget "https://btwifi.portal.fon.com/remote?res=hsp-login&HSPNAME=FonBT%3AGB&WISPURL=https%3A%2F%2Fwww.btwifi.com%3A8443%2FfonLogon&WISPURLHOME=https%3A%2F%2Fwww.btwifi.com%3A8443&VNPNAME=FonBT%3AGB&LOCATIONNAME=FonBT%3AGB"  --post-data "USERNAME=$user&PASSWORD=$pass" --no-check-certificate --no-cache --timeout=$timeout --tries=1 -O - -o /dev/null)
	elif [ "$BT_type" = 'BT Wifi' ]; then
		response=$(/usr/bin/wget "https://192.168.23.21:8443/wbacOpen?username=$user&password=$pass" --no-check-certificate --no-cache --timeout=$timeout --tries=1 -O - -o /dev/null)
	else
		echo "Unknown connection type for $BT_type"
		return 4
	fi

	bar=$(echo $response | /bin/grep "wbacClose") || bar=$(echo $response | /bin/grep "accountLogoff")

	if [ $? -eq 0 ]; then
		[ $syslog ] && /usr/bin/logger -t $processName[$pid] "Success!"
		return 0
	else
		[ $syslog ] && /usr/bin/logger -t $processName[$pid] "Oops!"
		return 5
	fi
}

###
# Main script routine
###

processName=$(echo $0 | /bin/sed 's/.*\/\(.*\)/\1/g')
pid=$$

sleepTime=0
timeout=30

parseCommandLine $@

# Try to login ...
while true; do
	doLogin

	if [ $sleepTime -ge 1 2>/dev/null ]; then
		[ $syslog ] && /usr/bin/logger -t $processName[$pid] "Checking again in $sleepTime seconds ..."
		sleep $sleepTime
	else
		exit 0
	fi
done

