# BTLogin

This is a fork of [g0wfv/BTLogin](https://github.com/g0wfv/BTLogin) by [Tony Corbett](https://github.com/g0wfv)

BTWifiLogin is a simple shell script to automate BT Wi-Fi logins in a headless environment to avoid the need to manually login from a browser. I use this script on a [GL.iNet Beryl AX (GL-MT3000)](https://www.gl-inet.com/products/gl-mt3000/) router which I use to connect to BT Wi-Fi in repeater mode so I can connect devices that do not have a GUI via a secure private WiFi network.

### Usage

````
bt_login.sh [-h|--help] [-s|--syslog] [-t|--timeout n] [-d|--debug] [wait]

    Options:
        -h      --help         Display this help
        -s      --syslog       Log result to syslog
        -t n    --timeout n    Wait n seconds for a reply [default 30]
        -d      --debug        Enable debug logging
        wait                   An integer value to wait between checks.
                               The script will loop continuously checking your login
                               status. Without it, the script will check once and
                               terminate.
````

### Installation

There are a few ways to install this script.  If you plan to run this on OpenWRT, ensure you install the full `wget` package via Luci or `ssh` ...

````
opkg update
opkg install wget
````

Place `bt_wifi_login.sh` in a convenient location and edit the `user` and `pass` variables to suit.

````
wget https://raw.githubusercontent.com/davidesewell/BTWiFiLogin/master/bt_login.sh
chmod a+x bt_wifi_login.sh
````

To auto start the script when the device boots, add the script to `/etc/rc.local` either through `ssh` or in Luci (System > Startup)

````
# Put your custom commands here that should be executed once
# the system init finished. By default this file does nothing.

/path/to/bt_wifi_login.sh -s 20 >/dev/null 2>&1 &

exit 0
````

### Script explanation (by ChatGPT)
This shell script checks if the device is connected to a BT Wi-Fi hotspot, and if not, attempts to connect. The script first defines several functions: hasBTWiFi(), checkConnection(), checkLoginServer(), doLogin(), and doRestartWWAN().

The hasBTWiFi() function checks if the device is connected to a BT Wi-Fi hotspot by using the iwinfo command to get a list of available wireless networks and then grepping for "BTWi-fi". If the device is connected to the hotspot, it returns 0, otherwise it returns 4.

The checkConnection() function pings a DNS server to test internet connectivity. If the ping is successful, it returns 0, otherwise it returns 4.

The checkLoginServer() function tests connectivity to the BT Wi-Fi login server by using curl to request a webpage from the server. It checks for several error conditions (such as a failure to resolve the server's DNS name), and returns 6 if there is an error, or 0 if the server is reachable.

The doLogin() function attempts to log in to the BT Wi-Fi hotspot by sending a POST request to the login URL with the user's credentials. If the login is successful (as determined by checking the response for the string "now logged in"), it returns 0, otherwise it returns 4.

The doRestartWWAN() function restarts the WWAN interface (which provides cellular data connectivity) if the device cannot connect to the BT Wi-Fi login server.

Finally, the doBTWiFi() function orchestrates the connection process by calling the other functions in sequence. If checkConnection() returns 0, indicating that the device already has internet connectivity, the function returns immediately. Otherwise, it calls checkLoginServer() to test connectivity to the login server. If checkLoginServer() returns 6, indicating an error, doRestartWWAN() is called to attempt to reset the WWAN interface. If checkLoginServer() returns a non-zero value, indicating that the device is connected to the BT Wi-Fi hotspot but does not have internet connectivity, doLogin() is called to attempt to log in.

The script then defines a loop that calls hasBTWiFi() and doBTWiFi(), sleeping for a specified amount of time between iterations. The loop continues until the device has successfully logged in or the script is terminated.

