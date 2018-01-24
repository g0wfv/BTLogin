#! /bin/sh

# bt_login.sh - A simple shell script to automate BT FON logins.
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

user=UsErNaMe
pass=PaSsWoRd

parseCommandLine()
{
	# Parse command line arguments ...
	while [ $# -gt 0 ]; do
		case $1 in
			-h|--help)
				cat << EOF
$processName - A simple shell script to automate BT FON logins.
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
	foo=$(/usr/bin/wget https://192.168.23.21:8443/home --no-check-certificate --timeout=$timeout --tries=1 -O - -o /dev/null)

	if [ $? -ne 0 ]; then
		[ $syslog ] && /usr/bin/logger -t $processName[$pid] "No reply from the BT Wi-fi login server."
		return 1
	fi

	bar=$(echo $foo | /bin/grep 'You may have lost your connection to the BTWiFi signal')
		
	if [ $? -eq 0 ]; then
		[ $syslog ] && /usr/bin/logger -t $processName[$pid] "Not connected to a BT Wi-fi hotspot."
		return 2
	fi

	bar=$(echo $foo | /bin/grep 'now logged in to BT Wi-fi')

	if [ $? -eq 0 ]; then
		[ $syslog ] && /usr/bin/logger -t $processName[$pid] "Already logged in. Nowt to do!"
		return 3
	fi

	[ $syslog ] && /usr/bin/logger -t $processName[$pid] "Attempting log on ... "
	foo=$(/usr/bin/wget "https://192.168.23.21:8443/wbacOpen?username=$user&password=$pass" --no-check-certificate --no-cache --timeout=$timeout --tries=1 -O - -o /dev/null)
	bar=$(echo $foo | /bin/grep "wbacClose")

	if [ $? -eq 0 ]; then
		[ $syslog ] && /usr/bin/logger -t $processName[$pid] "Success!"
		return 0
	else
		[ $syslog ] && /usr/bin/logger -t $processName[$pid] "Oops!"
		return 4
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

