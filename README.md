# twrnip-post

A client for posting Dynamic IP addresses to twitter.

The typical place to install this is a home router using OpenWRT.


## What is twrnip?

Twrnip is a protocol for doing over twitter what you usually would do using a Dynamic DNS service: have your temporary IP address
available for all to see.

This service is half of the solution: it will tweet your IP address as soon as it changes. It will also delete the previous obsolete announcement, of course.

Then anyone (including yourself) can check the announcement and copy&paste the IP into a web browser, or stream them in using the twitter API and configure a DNS, or patch the hosts file, you get the idea. 

The messages look as follows:

    #twrnip 
    #homerouter
    179.25.7.166

The #twrnip at the beginning indicates that this is a twrnip message, then might come some additional tags (in case the user has several services)
and finally an IP address.

No, it won't publish port numbers, because that would cross network layers.


## Installation

You will need some packages. If you are installing into a OpenWRT device, do

    $ opkg update; opkg install openssl-util, lua, luasocket, luasec

These are dependencies for the bbl-twitter library (some could be already installed)

Copy the following files

* `bbl-twitter.lua`
* `twrnip.lua`
* `twrnip.conf`

somewhere in the OpenWRT. For example, into a /root/twrnip directory:

    $ scp bbl-twitter.lua twrnip.lua twrnip.conf root@192.168.100.1:/root/twrnip/

You might edit the `twrnip.conf` file to change, for example, what additional tags you want posted. Also there you can change
the name of the interface whose IP you want to publish (usually `pppoe-wan`, but it might be `ppp0` or something).

Then log in into OpenWRT, go to the directory where you installed, and run the tool manually doing `$ lua twrnip.lua` to authenticate with twitter.com

You'll be instructed to follow a link and then write in a PIN number found on that page. Just follow the on-screen instructions.
Once the authentication is complete 3 files will be generated: `token.key`, `token.secret` and `screen.name`. You might save these files
for use in another installation (I think).

Once this is done you may test the installation doing `$ lua twrnip.lua` again. This should post a tweet with you IP address.

To automate the execution of the tool on IP changes copy the `99-twrnip` file into `/etc/hotplug/iface/`. Notice this is for 12.09 
"Attitude Adjustment" and newer OpenWRTs that use hotplug. 
You will have to edit this file if you installed the tool somewhere besides `/root/twrnip/`. 
Also this script watches the `wan` interface to detect a renumeration, so if you changed that in OpenWRT, 
edit this file. You can test everything forcing a IP renumeration doing `ifup wan`.


## License

This is licensed under MIT, see COPYRIGHT file.


## Who?

Copyright (C) 2014 Jorge Visca, jvisca@fing.edu.uy


