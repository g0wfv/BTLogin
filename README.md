# BTLogin

BTLogin is a simple shell script to automate BT FON logins in a headless environment when a GUI web browser is not available.

### Tested

To install, copy `bt_login.sh` to a convenient location, edit the `user` and `pass` variables to suit and add it as a cron job.

```
crontab -e

* * * * * /path/to/bt_login.sh 1>/dev/null 2>&1
```

The above example will run the script every minute to check you're logged in.

### Untested!
It is possible the script could be run from `/etc/network/interfaces` although I haven't tested used this method.  A possible configuration for this could look like this ...

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
The script first checks that you have an internet connection by seeing if it can contact the btopenzone.com login server.  If it can, it also checks you are connected to one of the BT Wifi hotspot SSIDs (I got the list off my mobile phone which uses the BT Wifi app; the app in turn adds all the possible SSIDs to your saved networks.) If all is still OK at  this stage, your current login status is determined.  If you are already logged in, it will exit.  If you are logged out, it will attempt to log you in.  Nothing could be simpler.

### Future development
It is very conceivable that this script could be used as the basis for other open Wifi hotspots (o2, Virgin Media, etc) that require you to log in via a web form.  If you do use this script in this manner, please consider submitting the resulting script as an extra, ie, `o2_login.sh` or similar. 
