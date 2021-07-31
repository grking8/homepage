---
layout: post
title:
  Host a static website with a custom domain over HTTPS using Google Cloud
  Storage and Cloudflare
author: familyguy
comments: true
tags: gcp ssl-certificates cloudflare https
---

{% include post-image.html name="https-static-website.png" width="100" height="100" alt="" %}

## Motivation

One way to host a static website for free with a custom domain over HTTPS is to
take advantage of a cloud computing provider's free tier:

- Start a small instance part of the free tier and let it run indefinitely, e.g.
  GCP's `f1-micro` VM instance in the `us-west1`, `us-central1`, or `us-east1`
  regions
- Run a web server, e.g. Nginx, on the instance
- Generate an SSL certificate using Let's Encrypt
- Configure the web server to serve traffic over HTTPS using the certificate

The main problems with this approach are:

- Renewal of Let's Encrypt certificates which expire after 90 days (unless you
  are using Caddy as your web server)
- Increases in traffic above a certain (quite low) threshold can cause the web
  server to stop handling requests
- Carbon footprint associated with running an instance 24/7

In this post, we go through an alternative approach which mitigates or resolves
each of the problems above.

[Cloudflare and GCP for hosting a static site](https://medium.com/@pablo.delvalle.cr/google-cloud-storage-for-affordable-simple-static-site-hosting-c6ceb473db40)
and
[static site hosting using Google Cloud Storage and Cloudflare](https://devopsdirective.com/posts/2020/10/gcs-cloudflare-hosting/)
were both useful references for this post and contain additional details.

## Prerequisites

Ownership of a domain `<my-domain>`.

## Approach

- Upload website files to a bucket in Google Cloud Storage
- Use Cloudflare for SSL termination and as a proxy for the bucket
- Serve the site at `https://www.<my-domain>`, i.e. requests to the URLs below
  redirect to `https://www.<my-domain>`:
  - `http://<my-domain>`
  - `http://www.<my-domain>`
  - `https://<my-domain>`

### Pros

- Cloudflare automatically handles renewal of SSL certificates
- Scales well as traffic increases as files served from a Cloud Storage bucket
- Reduced carbon footprint (I have not personally confirmed this, but
  intuitively it seems true)

### Cons

- Need to create an account with another vendor (Cloudflare)
- Need to pay a small amount of money each month (however, for low traffic
  websites, e.g. personal blog, equates to a few pennies each month)
- Spikes in traffic could lead to a larger than expected bill
- Bills are potentially uncapped
- SSL termination happens on Cloudflare meaning data from Cloudflare to GCP is
  not encrypted (problematic if there is sensitive information on your website)

### GCP alternatives

- Firebase (behind the scenes runs within GCP, but has a separate console and
  tooling)
- App Engine (unnecessary complexity as supports server-side apps also)
- Load balancer (relatively speaking, expensive)

### AWS alternatives

The main AWS alternative is S3 + CloudFront + ACM (more complicated to setup)

## DNS configuration and verification

### Transfer the nameserver from your existing DNS registrar to Cloudflare

- Create a Cloudflare account and login
- Add a site `<my-domain>` -> Select the free plan -> Import the DNS settings ->
  Click "Continue"
- Follow the steps to change your nameservers, i.e. in the domain registrar
  console, remove the current namerservers and replace them with the Cloudflare
  nameservers
- Wait for the change to propagate, e.g. wait for all checks to turn green on a
  [DNS checker](https://dnschecker.org/)
- Click "Check nameservers" in Cloudflare
- Refresh the browser. If the transfer is complete, you will see "Great news!
  Cloudflare is now protecting your site" or similar

### Perform DNS verification so Google knows you are the domain owner

- Login to Google Search Console using your GCP credentials
- Click add property and enter `<my-domain>`
- In Cloudflare -> DNS, add a TXT record for `<my-domain>` using the value given
  in the previous step (if there is already a TXT record for `<my-domain>`,
  update the existing record's value)
- Wait for the change to propagate
- Click verify in Google Seach Console, should get an "Ownership verified"
  confirmation

### Point CNAME records to Google Cloud Storage

- In Cloudflare -> DNS, create two CNAME records (again if they are already
  there, update them):
  - Name `www` and content `c.storage.googleapis.com`
  - Name `<my-domain>` and content `c.storage.googleapis.com`
  - If there is an A record pointing to `<my-domain>`, delete it
- Wait for the change to propagate (whilst waiting, continue the steps below)

## Upload the files to a Cloud Storage bucket

- Login to GCP -> Cloud Storage
- Create a bucket called `www.<my-domain>`
- For the location type, select single region and choose your region
- Under "Choose how to control access to objects", uncheck "Enforce public
  access prevention on this bucket"
- Upload website files to bucket, in particular the landing page (assumed here
  to be `index.html`) and an error page (assumed here to be `404.html`)
- GCP -> Cloud Storage -> Click ellipses on the row of your bucket -> Edit
  website configuration -> Set main page to `index.html` and error page to
  `404.html`
- GCP -> Cloud Storage -> Bucket `www.<my-domain>` -> Permissions -> Add member
  -> Select `allUsers` with the `storage object viewer` role (under
  `Cloud Storage`)

## Complete Cloudflare configuration

### SSL

Under SSL/TLS, select Flexible (seems to be the default)

### Redirects

For each rule below, go to Rules and create a page rule

#### www HTTP to www HTTPS

- For "If the URL matches" URL, enter `www.<my-domain>/*`
- For "Then the settings are", enter `Always use HTTPS`

#### Root domain HTTP to www HTTPS and root domain HTTPS to www HTTPS

- For "If the URL matches" URL, enter `<my-domain>/*`
- For "Then the settings are", enter `Forwarding URL` with "Destination URL"
  `https://www.<my-domain>/$1` and "Status code" `301 - Permanent Redirect`

## Test the website

Once the changes to the CNAME records have propagated, check:

- The website is available, and `error.html` is returned for 404s
- The redirects work as expected
- The website is served over HTTPS
- The SSL certificate auto-renews (will have to wait a while!)

Note: the SSL certificate might be from Cloudflare or Let's Encrypt. In both
cases, the certificate should auto-renew.
