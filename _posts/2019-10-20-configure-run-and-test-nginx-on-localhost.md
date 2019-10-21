---
layout: post
title: Configure, Run, and Test Nginx on Localhost
author: familyguy
comments: true
tags: nginx docker nginx-configuration allowed-hosts web-cache-poisoning
---

{% include post-image.html name="download.png" width="300" height="200" 
alt="nginx logo" %}

When making changes to your Nginx configuration for your staging
or production (or any other remote) environments, typically
this takes some time as you have to push changes sure you
can just do it directly on the server but this is bad
plus also the config files are usually version controlled so 
this would not work as well as it being bad practice (when
in the instance, what happens if you delete modify a file
incorrectly etc. there is no record of the change..)

So what would be nice is to test your changes to the config
first locally (like you would do with application code)

How to do this?
We will show you in this post.

We will use docker. Sure you can just download nginx on to 
your machine, but using Docker is just a bit cleaner
you start with a fresh config each time

things to test

- changing the response of the default homepage
- the classic allowed hosts django error - make it so that
only requests with the right host are served by nginx, 
everything else is rejected with 403 or similar response

Prerequisites 

Docker

Steps

- ```bash
docker run -it --publish 8000:80 nginx bash
```

- `service nginx status`

```
[FAIL] nginx is not running ... failed!
```

```bash
service nginx start
```

```
service nginx status
[ ok ] nginx is running.
```

Make a request to `http://localhost:8000` should see the 
Nginx homepage.

Similarly, in Python 

```python
import requests
r = requests.get('http://localhost:8000')
r.status_code
r.text
```

Meanwhile you will see the nginx logs get written to standard
out in the container 

```
172.17.0.1 - - [20/Oct/2019:16:52:04 +0000] "GET /favicon.ico HTTP/1.1" 404 555 "http://localhost:8000/" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.120 Safari/537.36" "-"
172.17.0.1 - - [20/Oct/2019:16:53:21 +0000] "GET / HTTP/1.1" 200 612 "-" "python-requests/2.18.4" "-"
172.17.0.1 - - [20/Oct/2019:16:55:26 +0000] "GET / HTTP/1.1" 200 612 "-" "python-requests/2.18.4" "-"
```

`apt-get update`
`apt-get install vim -y`

the nginx config file is `/etc/nginx/conf.d/default.conf`

You can see the file it is serving up

Go to this file in the container and change it then 

`service nginx reload`

should see changes appear in browser or when making a request
via Python

https://serverfault.com/questions/180827/nginx-is-defaulting-all-requests-to-what-should-be-a-vhost/180956#180956

https://stackoverflow.com/questions/17149435/avoiding-djangos-500-error-for-not-allowed-host-with-nginx

now trying making a request and setting your own host in requests

https://stackoverflow.com/questions/29995133/python-requests-use-navigate-site-by-servers-ip

at first no difference this is because if no matching 
server blocks are found, nginx uses the first one

But  if we set our host to `abc.com` and add to the bottom of 
the config

```
server {
    listen 80;
    server_name abc.com;
    return 403 "Forbidden";
}
```

it will give a 403. Now if we try a request to xyz.com it will
be a 200 again. If we add instead the above block to the top 
of the config, a request to `xyz.com` will 403.

So if we want all non host header localhost requests to go 
to 403, we can just add to the top

server {
    listen 80;
    return 403 "Forbidden";
}
```
 
which is equivalent to 

server {
    listen 80 default_server;
    return 403 "Forbidden";
}
```

which is more conventional and explicit?

why is this a problem - web cache poisoning
