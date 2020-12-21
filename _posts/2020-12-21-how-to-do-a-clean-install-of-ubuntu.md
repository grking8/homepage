---
layout: post
title: How to do a clean install of Ubuntu
author: familyguy
comments: true
tags: ubuntu
---

{% include post-image.html name="cof_orange_hex_400x400.jpg" width="100" height="100"
alt="ubuntu logo" %}

## Download the ISO

From the [official Ubuntu website](https://ubuntu.com/), download the ISO disk
image of the version of Ubuntu you would like to install.

The size of the ISO file is usually quite large, e.g. over a gigabyte, so the
download might take a while.

Once it is downloaded, if you inspect the properties of the file, it should say
the type of the file is `"raw CD image (application/x-cd-image)"` or similar.

## Create a USB bootable version

Insert a clean USB device into your machine.

[Download UNetbootin](https://unetbootin.github.io/), e.g. on Ubuntu 20.04:

`sudo add-apt-repository ppa:gezakovacs/ppa`

`sudo apt-get update`

`sudo apt-get install unetbootin`

Open the UNetbootin application,

`sudo unetbootin`

and in the window select "Disk image", "ISO", and specify the path to the ISO
file downloaded in the previous step.

Make sure the correct USB drive has been detected.

Click "OK".

UNetbootin should then start creating a USB bootable version of the ISO on your
USB device (this might take a few minutes).

## Install from USB

### Configure BIOS

Insert the USB device into the machine on which you would like to install Ubuntu
(the machine should be turned off).

Turn on the machine and press the relevant key, e.g. F2, to go into Basic Input
/ Output System (BIOS) mode.

In BIOS mode, look for boot settings and change the boot order so the USB device
is first.

Exit and save. The machine should now boot up using the contents of the USB
device (you should see a UNetbootin screen).

### Install

Once the machine has booted up, you should something resembling Ubuntu. On the
desktop, there should be an icon "Install Ubuntu" or similar.

Start the installation wizard via the icon. For this step, the machine does not
need to be connected to the Internet.

The wizard will take you through several steps. Amongst other things, it will
ask you to:

- Choose what kind of installation to do (dual boot, delete the existing
  installation, etc.)
- Set the timezone and language
- Set the computer name
- Set a user account and password

After you have made your selections, the wizard will carry out the installation
(this might take a few minutes).

When the installation has completed, you will be prompted to restart the
machine.

## Restart

During restart, enter BIOS mode and change the boot order back to its original
value.

Save and exit. In a few moments you should see the Ubuntu desktop (but not the
"Install Ubuntu" icon), and your clean installation should be ready to go.

To verify everything is correct:

- Click "About This Computer" and check the correct version of Ubuntu is
  displayed
- Eject the USB device and restart the machine
