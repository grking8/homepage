---
layout: post
title: Desktop Notifications on Ubuntu 16.04 for Long Running Terminal Commands
author: familyguy
comments: true
tags: ubuntu terminal desktop-notifications
---

{% include post-image.html name="cof_orange_hex_400x400.jpg" width="100" height="100" 
alt="ubuntu logo" %}

Install [undistract-me](https://github.com/jml/undistract-me):

```bash
sudo apt-get install undistract-me
```
Update your `~/.bashrc`

```bash
$ echo 'source /etc/profile.d/undistract-me.sh' >> ~/.bashrc
```

Reload your Bash configuration

```bash
source ~/.bashrc
```

To test, execute in your terminal a command that takes more than ten seconds,
to complete, e.g.

```bash
sleep 11
```
and navigate away from your terminal to another window.

Once the command in the terminal completes, you should receive a desktop notification with the exit status of the command and the time it took.

The threshold of ten seconds can be configured

```bash
export LONG_RUNNING_COMMAND_TIMEOUT={new-threshold-in-seconds}
```

If you are happy with the new configuration, add the above to `~/.bashrc` or 
`~/.profile` or similar and reload the file.
