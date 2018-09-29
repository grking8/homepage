---
layout: post
title: HTTPS With Let's Encrypt, Nginx, And Docker
author: familyguy
comments: true
---

{% include post-image.html name="Whale Logo332_5.png" width="75" height="50" alt="Docker logo" %}

Suppose you have an Ubuntu instance (Google Compute Engine, Amazon EC2, etc.) running a web app via Nginx inside a Docker container and you would like the app to communicate over HTTPS.

There are numerous posts online on how to do this, usually using Nginx as a [reverse proxy](https://en.wikipedia.org/wiki/Reverse_proxy) and [Docker Compose.](https://docs.docker.com/compose/overview/) This is a powerful and general solution, but if you want a stopgap, read on.

## Step 1

As Nginx is currently running inside a Docker container, it probably isn't installed yet on the host instance itself

```
sudo apt-get update
sudo apt-get install nginx
```

## Step 2

[Let's Encrypt](https://letsencrypt.org/) is a free SSL/TLS certificate provider accepted by modern browsers for HTTPS communication. Certficates expire after three months and are renewable.

Installation and configuration is easiest via [certbot](https://certbot.eff.org/#ubuntuxenial-nginx) (follow the instructions under **Install**).

## Step 3

```
sudo certbot --nginx -d <mydomain>
```

replacing \<mydomain\> with the domain your app is currently being served from:

> Running this command will get a certificate for you and have Certbot edit your Nginx configuration automatically to serve it. 

When prompted, select `redirect all HTTP requests to HTTPS`.

At this stage, you can check everything works by starting Nginx (and stopping any processes running on ports 80 and 443)

```
sudo systemctl start nginx
```

then navigating in a browser to \<mydomain\>. You should see a padlock in the address bar and the default [Debian-Nginx message.](https://www.howtoforge.com/images/install_and_configure_lemp_in_debian_9/6.PNG)

After checking,

```
sudo systemctl stop nginx
```

## Step 4

Assuming your app's `Dockerfile` contains a line similar to `COPY ./path/to/my/html /usr/share/nginx/html`, in `/etc/nginx/sites-enabled/default` on the host instance, replace

```
root /var/www/html;
```

with 

```
root /usr/share/nginx/html;
```

and set the server name

```
server_name <mydomain>;
```

## Step 5

Add the below lines to the app's `Dockerfile`

```
RUN addgroup -g 1000 -S www-data \
&& adduser -u 1000 -D -S -G www-data www-data
```

and rebuild the Docker image.

## Step 6

Run the new Docker image, with some extra options:

```
--publish=443:443
```

to open up port 443;

```
--volume=/etc/letsencrypt/:/etc/letsencrypt/
```

to get the certificates (and other required Let's Encrypt files) on the host 
instance onto the container;

```
--volume=/etc/nginx/:/etc/nginx/
```

to ensure the container has the same Nginx configurations as the host instance.

The last option is why in Step 5 the [`www-data` user needs creating.](http://blog.tobiasforkel.de/en/2016/09/10/nginx-docker-container-and-getpwnamwww-data-problem/)

## Step 7

Navigate in the browser to \<mydomain\> (you should see your app running over HTTPS).
