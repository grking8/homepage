---
layout: post
title: Recover Firefox Tabs On Mac OS X
author: familyguy
comments: true
---

{% include post-image.html name="firefox.png" width="50" height="50" alt="Firefox logo" %}

If you lose unbookmarked tabs in Firefox and for whatever reason "History->Restore Previous Session" doesn't bring them back, all is not lost. You could regoogle them or sift through your search history.

However, there is an easier way *if your system files are backed up regularly,* e.g. via [Time Machine.](https://en.wikipedia.org/wiki/Time_Machine_(macOS)) In this case, the snapshot taken during the last backup will include files Firefox uses to restore previous sessions.

For brevity, the rest of this post assumes the path to your home directory is 

{% highlight bash %}
/home
{% endhighlight %}

In reality, it's probably something like

{% highlight bash %}
/Users/yourname
{% endhighlight %}

If you're not sure, 

{% highlight bash %}
echo $HOME
{% endhighlight %}

## Step 1

Unhide files in Finder. 

{% highlight bash %}
defaults write com.apple.finder AppleShowAllFiles -bool true &amp;&amp; osascript -e 'quit app "Finder"'
{% endhighlight %}

(restarts Finder).

## Step 2

Look in

{% highlight bash %}
/path/to/backup/home/Library/Application Support/Firefox/Profiles/vrjcwd35.default/sessionstore-backups
{% endhighlight %}

or a similar-looking path for the backups of

{% highlight bash %}
previous.js
recovery.bak
recovery.js
{% endhighlight %}

## Step 3

Find the current versions of the above files. They will probably be somewhere like

{% highlight bash %}
/home/Library/Application Support/Firefox/Profiles/vrjcwd35.default/sessionstore-backups
{% endhighlight %}

Close Firefox.

## Step 4

Replace the current versions with their backups. If you reopen Firefox, "History->Restore Previous Session" still does not work.

## Step 5

{% highlight bash %}
cd /home/Library/Application Support/Firefox/Profiles/vrjcwd35.default
{% endhighlight %}

You should see

{% highlight bash %}
sessionstore.js
{% endhighlight %}

Rename it to 

{% highlight bash %}
sessionstore.old
{% endhighlight %}

"History->Restore Previous Session" should now work. If your system does an hourly backup, for example, you will have lost at most one hour's worth of tabs.

## Step 6

Delete 

{% highlight bash %}
sessionstore.old
{% endhighlight %}

and

rehide files in Finder

{% highlight bash %}
defaults write com.apple.finder AppleShowAllFiles -bool false &amp;&amp; osascript -e 'quit app "Finder"'
{% endhighlight %}

For more details on what you just did, see [what happens when you close Firefox.](https://support.mozilla.org/en-US/questions/1088713)

P.S. Close Firefox here means exiting the application completely, not closing tab(s) / window(s), after which "History->Restore Previous Session" is used, as supposed to "History->Recently Closed Tabs" or "History->Recently Closed Windows."
