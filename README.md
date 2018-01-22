# BTLogin

BTLogin is a simple shell script to automate BT FON logins in a headless environment when a GUI web browser is not available.

### Tested

To install, copy `bt_login.sh` to a convenient location, edit the `user` and `pass` variables to suit.

````
wget https://raw.githubusercontent.com/g0wfv/BTLogin/master/bt_login.sh
chmod a+x bt_login.sh
````

BTLogin can be run either run as a cron job ...

```
crontab -e

* * * * * /path/to/bt_login.sh >/dev/null 2>&1
```

The above example will run the script every minute.

... or if you plan to run this on OpenWRT/LEDE you need to install the full `wget` package via Luci or `ssh` ...

````
opkg update
opkg install wget
````

Add the script to `/etc/rc.local` either through `ssh` or in Luci (System > Startup)

````
# Put your custom commands here that should be executed once
# the system init finished. By default this file does nothing.

/path/to/bt_login.sh 60 &
exit 0
````

... and reboot your router.

The script accepts an optional command line argument.  This makes it loop indefinitely checking the connection every x seconds.  Without the command line arguement, it checks the connection once and terminates (crontab mode)

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
