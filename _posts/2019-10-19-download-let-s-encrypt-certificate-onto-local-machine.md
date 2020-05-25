---
layout: post
title: Download Let's Encrypt Certificate Onto Local Machine
author: familyguy
comments: true
tags: lets-encrypt certbot ssl-certificates docker
---

{% include post-image.html name="download.png" width="300" height="200" 
alt="lets encrypt logo" %}

This post describes how to download Let's Encrypt SSL files onto your 
local machine using the `certbot` command line tool.

It assumes you have Docker installed. If you don't, you
can install `certbot` directly and adapt the 
instructions in this post accordingly.

## Prerequisites

- Access to DNS settings for a domain `<my-domain>`, e.g. `example.com`
- Local installation of Docker

## Steps

### Step 1
Set the directory that `certbot` 
will output the SSL files to inside the Docker container

`export CERTBOT_DIR=/opt/certbot/my-output`

and the directory where you would like the files to go on your 
local machine

`export LOCAL_CERTBOT_DIR=/path/to/local/folder`

### Step 2
Run the `certbot` command via Docker to download the SSL files 
(including the certificate)

```bash
docker run --interactive --tty --volume $LOCAL_CERTBOT_DIR:$CERTBOT_DIR  \
certbot/certbot \
    -d <my-domain> \
    --manual \
    --agree-tos \
    --manual-public-ip-logging-ok \
    --email <my-email> \
    --logs-dir $CERTBOT_DIR \
    --config-dir $CERTBOT_DIR \
    --work-dir $CERTBOT_DIR \
    --preferred-challenges dns \
    certonly
```

### Step 3
After following the prompts, you will be instructed to deploy a DNS text record

`Please deploy a DNS TXT record under the name`
`_acme-challenge.<my-domain> with the following value:`

`<value>`

`Before continuing, verify the record is deployed.`
`-------------------------------------------------------------------------------`
`Press Enter to Continue`

Go into the DNS configuration of your domain registrar and create a new record
- Type: `TXT`
- Name: `_acme-challenge`
- Value: `<value>`

Depending on your DNS provider, the name might be `_acme-challenge` or 
`_acme-challenge.<my-domain>` for Apex domains. If `<my-domain>` is a subdomain,
e.g. `www.example.com`, the name could be `_acme-challenge.www` or 
`_acme-challenge.www.example.com`

### Step 4
Verify the record has been added 

`dig -t txt _acme-challenge.<my-domain>`

For example, `dig -t txt _acme-challenge.www.example.com`

(in the answer section, look for something like below)

`;; ANSWER SECTION:`

`_acme-challenge.<my-domain>. 300 IN	TXT	<value>`

This can sometimes take a while, but once it's done, press `Enter`

If successful, you will see something like

`Congratulations! Your certificate and chain have been saved at:`

`${CERTBOT_DIR}/live/<my-domain>/fullchain.pem`

`Your key file has been saved at:`

`${CERTBOT_DIR}/live/<my-domain>/privkey.pem`

where `fullchain.pem` is the SSL certificate file and `privkey.pem` the SSL private key file.

### Step 5
Check the SSL files are available locally 

`ls $LOCAL_CERTBOT_DIR/live/<my-domain>` 

(you might have to change to superuser first `sudo su`)
