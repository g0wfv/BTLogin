#! /bin/bash

# bt_login.sh - A simple shell script to automate BT FON logins.
# Copyright (C) 2017  Tony Corbett, G0WFV

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

shopt -s extglob         # enables pattern lists like +(...|...)
listOfESSID='+(BTFON|BTOpenzone|BTOpenzone-B|BTOpenzone-H|BTWi-fi|BTWifi|BTWiFI-with-FON|BTWifi-with-FON|_BTWi-fi)'
currentESSID=$(iwgetid | sed 's/.*\"\(.*\)\".*/\1/g')

foo=$(wget "https://www.btopenzone.com:8443/home" --no-check-certificate --no-cache --timeout 30 -O - 2>/dev/null)

if [ $? -ne 0 ]
then
	echo "There isn't an internet connection. Exiting."
	exit $?
fi

loggedIn=$(echo $foo | grep 'now logged on to BT Wi-fi')

if [ $? -eq 0 ]
then
	echo "You're already logged in. Nowt to do!"
	exit 0
else
	echo -n "$currentESSID "
	case "$currentESSID" in
		$listOfESSID)
			echo -n "is a valid Wifi network. Logging in ... "
			foo=$(wget -qO - --no-check-certificate --no-cache --post-data "username=$user&password=$pass" "https://www.btopenzone.com:8443/tbbLogon")
			loggedIn=$(echo $foo | grep 'now logged on to BT Wi-fi')

			if [ $? -eq 0 ]
			then
				echo "Success!"
				exit 0
			else
				echo "Oops!"
				exit 1
			fi
		;;

		*)
			echo "is not in the list of valid Wifi networks."
			exit 1
	esac
fi
