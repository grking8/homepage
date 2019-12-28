---
layout: post
title: BT WiFi Connectivity Issues on Ubuntu 16.04
author: familyguy
comments: true
tags: ubuntu wifi
---

{% include post-image.html name="cof_orange_hex_400x400.jpg" width="100" height="100" 
alt="ubuntu logo" %}

Symptoms of the problem

Unable to connect to the network, (wifi symbol keeps flashing)
Able to connect to the network but:
- Unable to browse in chrome
- `ping google.com` does not work
- `nslookup google.com` does not work
- able to do all of the above on another laptop and browse in chrome on mobile
- `ping 8.8.8.8` does not work
- Works for about half an hour and then cuts off again
- But on ubuntu, can connect to other wifi networks fine e.g. 4g




```bash
guy@n24-25bu:/etc/dhcp$ netstat -rn
Kernel IP routing table
Destination     Gateway         Genmask         Flags   MSS Window  irtt Iface
0.0.0.0         192.168.1.254   0.0.0.0         UG        0 0          0 wlp2s0
169.254.0.0     0.0.0.0         255.255.0.0     U         0 0          0 docker0
172.17.0.0      0.0.0.0         255.255.0.0     U         0 0          0 docker0
192.168.1.0     0.0.0.0         255.255.255.0   U         0 0          0 wlp2s0
```

then `ip route get 192.168.1.0`

which gives

```bash
broadcast 192.168.1.0 dev wlp2s0  src 192.168.1.131 
    cache <local,brd> 
```

then ping `192.168.1.131` works

but the other local IPs dont

Actually it seems the problem might be due to the wifi network itself
as it stopped working on all devices (macbook, android phone)

But the last thing tried was to disable the power management of the wireless
card which can be viewed with `iwconfig`

and changed with `sudo vi /etc/NetworkManager/conf.d/default-wifi-powersave-on.conf`
setting `wifi.powersave = 2` from `wifi.powersave = 3`. (doing it another way
does not make the change permanent)

There was also something odd where navigating to `192.168.1.131` brought up the
nginx welcome page (which was also running at localhost)

This was because nginx was being loaded on start up, so disabled this with
`sudo update-rc.d -f nginx disable`

When the wifi is working, `sudo service nginx start` only brings up the nginx
page at localhost, it no longer appears at `192.168.1.131`.