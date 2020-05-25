---
layout: post
title: Configure, Run, and Test Nginx on Localhost
author: familyguy
comments: true
tags: nginx docker nginx-configuration django-allowed-hosts web-cache-poisoning
---

{% include post-image.html name="download.png" width="300" height="200" 
alt="nginx logo" %}



When testing changes to your Nginx configuration for your staging
or production (or any other remote) environments, one can 
encounter problems:

- If the changes are made as part of a CI/CD pipeline, 
each change requires you to wait for the pipeline to build
before testing. This waiting time will typically be minutes
rather than seconds
- Making the changes directly to the configuration files on 
the server means you can test your changes basically straight away. However,
    - If you have a load balancer directing traffic to more
    than one instance, you have to make the same change in 
    several places
    - If you have a load balancer and your instances are in a
    private subnet, SSH-ing into those instances requires 
    setting up a VPN
    - Changing files directly on a server is bad practice as 
    there is no record of those changes. What happens if you 
    would like to revert a mistake?

One way around this is to test your Nginx configuration changes
locally (like you would with regular application code).

In this post we will show how to do this.

## Prerequisites

- Docker; whilst you could download Nginx directly onto your 
machine, using Docker means you can easily:
    - Install and uninstall Nginx
    - Reset your Nginx configuration files
    - Run multiple Nginx processes at the same time
    - Change the port Nginx runs on
    - Change Nginx version..., etc. 

## Getting started

To run Nginx in a Docker container and serve requests on 
port 8000 on your machine,

`docker run --interactive -tty --publish 8000:80 nginx bash`

(if you are on macOS, you might have to start the
Docker daemon first by clicking on an icon)

This command also SSHs you into the container.

In the container shell, check Nginx is installed 

`which nginx`

`/usr/sbin/nginx`

and that it is running

`service nginx status`

`[FAIL] nginx is not running ... failed!`

As it is not running, start it

`service nginx start; service nginx status`

`[ ok ] nginx is running.`

Make a request to `http://localhost:8000` in the browser. You should see the 
`"Welcome to nginx!"` page.

Similarly, in Python

```python
import requests

r = requests.get('http://localhost:8000')
r.status_code
r.text
```

you should get back the HTML of the page and the response
status code.

You should also see the relevant logs in the container 
shell

`172.17.0.1 - - [21/Oct/2019:17:53:21 +0000] "GET /favicon.ico HTTP/1.1" 404 555 "http://localhost:8000/" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.120 Safari/537.36" "-"`

`172.17.0.1 - - [21/Oct/2019:17:54:51 +0000] "GET / HTTP/1.1" 200 612 "-" "python-requests/2.18.4" "-"`

## Changing the "Welcome to nginx" page

To make changes to the Nginx configuration, we will need to edit
files inside the container shell.

By default, there is no text editor inside the container
shell.

We will install Vim, but any text editor will do.

Inside the container shell,

- `apt-get update`
- `apt-get install vim --yes`

We can now use our text editor to have a look at the Nginx
configuration

- `cd /etc/nginx/conf.d`
- `vi default.conf`

You should see the following configuration or similar

```nginx
server {
    listen       80;
    server_name  localhost;

    #charset koi8-r;
    #access_log  /var/log/nginx/host.access.log  main;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }

    #error_page  404              /404.html;

    # redirect server error pages to the static page /50x.html
    #
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }

    # proxy the PHP scripts to Apache listening on 127.0.0.1:80
    #
    #location ~ \.php$ {
    #    proxy_pass   http://127.0.0.1;
    #}

    # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
    #
    #location ~ \.php$ {
    #    root           html;
    #    fastcgi_pass   127.0.0.1:9000;
    #    fastcgi_index  index.php;
    #    fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
    #    include        fastcgi_params;
    #}

    # deny access to .htaccess files, if Apache's document root
    # concurs with nginx's one
    #
    #location ~ /\.ht {
    #    deny  all;
    #}
}
```

As the web server document root is `/usr/share/nginx/html`,
inside `/usr/share/nginx/html` is `index.html`. 

Change `index.html` so that the title and header reads
`"Bienvenue a nginx!"` instead of `"Welcome to nginx!"`.

To let the changes take effect, restart Nginx

`service nginx reload`

When you make a request to `http://localhost:8000`, you should
see the new title and header.

## Changing the Nginx configuration to prevent web cache poisoning

[Web cache poisoning:](https://www.theregister.co.uk/2018/08/17/web_cache_poisoning/)

> Web cache poisoning is geared towards sending a request that causes a harmful response that then gets saved in the cache and served to other users.

One method of web cache poisoning starts with 
spoofing the host in the request header.

For example, if your website is written in Django, Django uses 
the host in the request header when generating its URLs. 

Thus if you have a Django URL `/my-login`, and the host in the
request header is `malicious-hacker.com` (although your site's
domain is `my-site.com`), if Django internally makes requests
to `/my-login`, these requests will go to
`http://malicious-hacker.com/my-login` and not
`http://my-site.com/my-login`.

`http://malicious-hacker.com/my-login` then sends a harmful
response that gets saved in the cache and served to other users.
Web cache poisoning complete!

To mitigate this security risk, Django has an `ALLOWED_HOSTS`
setting. 

By setting 

```python
ALLOWED_HOSTS = ['my-site.com']
```

Django will only make requests to `my-site.com`. If an attacker
sends a request with host `malicious-hacker.com`, it throws
a `SuspiciousOperation` error and returns a `Bad request` 
response with status code `400`.

One of the drawbacks of the above is that it usually leads to 
noisy logging due to bots checking for 
vulnerabilities in your site.

Assuming your website is served by Nginx, one way around
this is to configure Nginx so that any request with a host
in the header not equal to `my-site.com` is given a `4xx` 
error response (ideally, the error code should capture just
this issue as otherwise all you have done is transferred
your noisy logging problem from Django to Nginx).

Let's now test this workaround locally.

### Making a spoof request in Python

```python
import requests

url = 'http://localhost:8000'
headers = {'host': 'abc.com'}
r = requests.get(url, headers=headers)
```

The response is exactly the same as before, despite having 

`server_name  localhost;`

in our server block in `default.conf` and the host in the
request header being `abc.com`. 

### Changing the Nginx configuration

So why did we get a `200` response despite
the host in the Nginx configuration not matching the host sent
in the request?

This is because if Nginx finds no matching server blocks,
it uses the first server block.

To check this, let's add 

```nginx
server {
    listen 80;
    server_name abc.com;
    return 403 "Your request is forbidden";
}
```

to the end of `default.conf`. To make the changes take effect,

`service nginx reload`

Now, making the same request in Python, we get a response
status code of `403` with content

`'Your request is forbidden'`

However, if we spoof the header with a host different to 
`abc.com`, we will get a `200` again.

Actually, all we have to do is add

```nginx
server {
    listen 80;
    return 403 "Your request is forbidden";
}
```

to the start of `default.conf`.

Now, whenever the host in the header is not equal to 
`localhost`, a `403` is returned.

Although functionally it makes no difference, the convention
is to add `default_server` to the block, i.e. to have

```nginx
server {
    listen 80 default_server;
    return 403 "Your request is forbidden";
}
```

at the start of `default.conf`.

Now your Nginx configuration is setup to prevent web cache
poisoning!
