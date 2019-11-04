# BTLogin

BTLogin is a simple shell script to automate BT FON logins in a headless environment when a GUI web browser is not available.

### Usage

````
bt_login.sh [-h|--help] [-s|--syslog] [-t|--timeout n] [wait]

    Options:
        -h      --help         Display this help
        -s      --syslog       Log result to syslog
        -t n    --timeout n    Wait n seconds for a reply [default 30]
        wait                   An integer value to wait between checks.
                               The script will loop continuously checking your login
                               status. Without it, the script will check once and
                               terminate.
````

### Tested

There are a few ways to install this script.  If you plan to run this on OpenWRT, ensure you install the full `wget` package via Luci or `ssh` ...

````
opkg update
opkg install wget
````

Place `bt_login.sh` in a convenient location and edit the `user` and `pass` variables to suit.

````
wget https://raw.githubusercontent.com/g0wfv/BTLogin/master/bt_login.sh
chmod a+x bt_login.sh
````

1. Run as a cron job ...

```
crontab -e

* * * * * /path/to/bt_login.sh >/dev/null 2>&1
```

The above example will run the script every minute.


2. Add the script to `/etc/rc.local` either through `ssh` or in Luci (System > Startup)

````
# Put your custom commands here that should be executed once
# the system init finished. By default this file does nothing.

/path/to/bt_login.sh 60 &
exit 0
````

3. (RECOMMENDED) Install the `travelmate` package and set `bt_login.sh` as an Auto Login Script.

````
opkg update
opkg install travelmate luci-app-travelmate
ln -s /path/to/bt_login.sh /etc/travelmate/BTWifi-with-FON.login
````

![travelmate image](https://github.com/g0wfv/BTLogin/raw/master/travelmate.png "Travelmate config")

Finally, reboot your router!

### Untested!
It is possible the script could be run from `/etc/network/interfaces` although I haven't tested or used this method.  A possible configuration for this could look like this ...

```
auto lo
iface lo inet loopback

iface eth0 inet manual

allow-hotplug wlan0
iface wlan0 inet manual
    wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
    post-up /path/to/bt_login.sh
```

### Script methodology
The script first checks that you have an internet connection by seeing if it can contact the btopenzone.com login server.  If the server is detected, your current login status is determined.  If you are already logged in, it will do nothing.  If you are logged out, it will attempt to log you in.  Nothing could be simpler.

### Future development
It is very conceivable that this script could be used as the basis for other open Wifi hotspots (o2, Virgin Media, etc) that require you to log in via a web form.  If you do use this script in this manner, please consider submitting the resulting script as an extra, ie, `o2_login.sh` or similar. 

