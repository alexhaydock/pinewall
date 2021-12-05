```

     /\ /\          ____  _                          _ _ 
    // \  \        |  _ \(_)_ __   _____      ____ _| | |
   //   \  \       | |_) | | '_ \ / _ \ \ /\ / / _' | | |
  ///    \  \      |  __/| | | | |  __/\ V  V / (_| | | |
  //      \  \     |_|   |_|_| |_|\___| \_/\_/ \__'_|_|_|
           \
  
       A minimal Alpine Linux home Firewall / Router.

```

## Introduction

There's some controversy right now (March 2021) around Netgate and pfSense and I have been looking to explore alternatives for a while. I could jump ship to OPNSense, but it's based on FreeBSD just like pfSense and [FreeBSD's code quality is being called into question too](https://arstechnica.com/gadgets/2021/03/buffer-overruns-license-violations-and-bad-code-freebsd-13s-close-call/) at the moment.

Linux also seems to have the better networking stack these days (which Netgate seem to be well aware of as they base [their extremely high performance TNSR router](https://www.tnsr.com/) platform on Linux rather than BSD). You also get to [play with eBPF and XDP Hardware Offload](https://blog.cloudflare.com/how-to-drop-10-million-packets/) if you're lucky enough to have compatible gear.

If I had to pick a proper vendor-supported Linux-based routing platform to use, I would pick [VyOS](https://vyos.io/), the still-developed OSS fork of Brocade's Vyatta. But hey -- a home or SoHO firewall/gateway device is actually pretty a pretty simple set of features -- why not just build one from scratch? That idea became this project.


## Official Repository Links

* https://gitlab.com/pinewall/pinewall
* https://github.com/alexhaydock/pinewall


## What's the goal?

The core goals of this project are simplicity and minimalism. I want it to be my home router/gateway and nothing more.

At its core, a home router/firewall/gateway doesn't really do much. It routes, it NATs, and it does DHCP. That's about it. There are some other neat features you can add, and I have a feature matrix further down in this README, but those are the key features, and when your project has so few "moving parts", it makes sense to start from a very minimal state -- and that's where Alpine Linux comes in.

In brief, I want this project to:

* Replace pfSense in my home setup
* Be based on Linux rather than FreeBSD
* [Track a stable upstream release of the Linux kernel](https://security.googleblog.com/2021/08/linux-kernel-security-done-right.html)
* Be free of unnecessary complexity and attack surface (GUIs etc)
* Be minimal and simple to manage
* Be easy to back up and migrate config
* Be crash safe and resiliant to power loss (needs to run from RAM)
* Have full IPv6 support


## Who is this for?

Me.

This project is designed to be minimal and simple. The downside of this is that it may be slightly rigid in terms of conforming to my needs. If I don't need something, I didn't include it.

That said, I've tried my best to document everything as thoroughly as possible and I'm using this public repo as my actual development workspace for the live version of Pinewall that I'm running in production at home. The hope there is that the code and processes in use here may benefit others who wish to opt for a similar setup.

I'm also very willing to help out generally where I can if people get stuck (feel free to open issues) or want to try and implement something new on top of this. The best way to learn is through experimenting and trying to solve problems. I'm also open to sensible suggestions via PR that make the project a bit more adaptable to the needs of others (but without compromising the goals of simplicity and minimalism!).


## Is this a custom distro / is this a fork of Alpine?

Not really.

This is more of a set of scripts and configs that allows you to compose a custom Alpine Linux image that contains all the additional packages needed to run a Linux-based home router. This is paired with a second set of scripts and configs that allow us to build a filesystem overlay that our custom ISO will load into RAM while booting. Most of this is built around the native functionality provided by Alpine's [local backup utility](https://wiki.alpinelinux.org/wiki/Alpine_local_backup) - I've just tailored it specifically towards being a home router.


## Feature matrix

| Feature                           | Alpine Package      | Alpine Repo | Notes            |
|-----------------------------------|---------------------|-------------|------------------|
| 802.1Q VLANs                      | ifupdown-ng         | main        | Working          |
| DHCP Reservations                 | dhcp-server-vanilla | main        | Working          |
| DHCP Server                       | dhcp-server-vanilla | main        | Working          |
| DNS Cache                         | unbound             | main        | Working          |
| DNS Root Hints (for Unbound)      | dns-root-hints      | main        | Working          |
| DNS Server (Upstream via DoT)     | unbound             | main        | Working          |
| DNSSEC                            | unbound             | main        | Working          |
| Firewall                          | nftables            | main        | Working          |
| IPv6 Router Advertisements        | radvd               | main        | Working          |
| mDNS Proxy                        | avahi, dbus         | main        | Working          |
| NTP Server                        | chronyd             | main        | Working          |
| Performance Testing               | iperf3              | main        | Working          |
| Port Forwarding (Destination NAT) | nftables            | main        | Working          |
| PPPoE Connectivity                | ppp-pppoe           | main        | Working          |
| PPPoE Integration with ifupdown   | ifupdown-ng-ppp     | main        | Working          |
| Privilege Escalation              | doas                | main        | Working          |
| Remote Wireshark                  | tcpdump             | main        | Working          |
| Static Port NAT for Games         | nftables            | main        | Working          |
| TFTP Server (for PXE clients)     | tftp-hpa            | main        | Working          |
| Log Shipping                      | Splunk UF           | not in repo | Not started      |


## Every package added on top of the Alpine "Standard" profile by Pinewall

Below you can find a list of every package installed on top of the Alpine "Standard" profile. You can find these defined the `apks` variable inside either `mkimg.pinewall_x86.sh`, or `mkimg.pinewall_rpi.sh`.

| Package             | Repo      | Functionality         |
|---------------------|-----------|-----------------------|
| avahi               | main      | optional              |
| chrony              | main      | optional              |
| conntrack-tools     | main      | optional              |
| dbus                | main      | dependency (of avahi) |
| dhcp-server-vanilla | main      | core                  |
| dns-root-hints      | main      | core                  |
| doas                | main      | core                  |
| ethtool             | main      | optional              |
| htop                | main      | optional              |
| ifupdown-ng-ppp     | main      | core                  |
| iperf3              | main      | optional              |
| nano                | main      | optional              |
| nftables            | main      | core                  |
| nload               | main      | optional              |
| ppp-pppoe           | main      | core                  |
| radvd               | main      | core                  |
| tcpdump             | main      | optional              |
| tftp-hpa            | main      | optional              |
| unbound             | main      | core                  |


## What doesn't work?

* IPv6 ruleset for nftables
  * This definitely needs some work. I have a separate private repo that has my current live config in it and I have the rules working there, but the ones in this repo definitely need updating with the things I've learned about making IPv6 work well in a home network.
  * One resource I'd recommend for now which shows off a good IPv6 nftables ruleset would be [this post on the Alpine wiki](https://wiki.alpinelinux.org/wiki/Linux_Router_with_VPN_on_a_Raspberry_Pi_(IPv6)#nftables).
* DHCPv6
  * Currently I'm using SLAAC for IPv6 address configuration on my VLANs and not DHCPv6 or DHCPv6-PD. I statically assign `/64` prefixes for each of my VLANs in my ISP's control panel and manually add these to the `radvd.conf` file to be advertised on those interfaces via Router Advertisements.
  * I don't really have a need for DHCPv6 with this setup, but if I find a need in the future I will find a way to fit it into the current design.
* UPnP
  * I thought about this but ended up making a conscious choice not to support it. STUN and other methods of NAT punching offer a much more reliable service for games etc. and a lot don't even bother with UPnP anymore. Plus it's a security risk.
* Log monitoring and alerting
  * I haven't really decided on my solution for this yet, but it'll probably end up being the Splunk Universal Forwarder feeding the logs from `/var/log` into a remote Splunk Enterprise instance.


## How do I build this?

To build the Alpine image, seeded with the latest packages (you will need `podman` installed):
```bash
make x86
```

You will find an ISO image that can be booted either from disc or USB in the `images/` directory.

To build the Raspberry Pi disk image **(work in progress!)**:
```bash
make rpi
```

And to build the APK overlay based on `genapkovl-pinewall.sh`:
```bash
make overlay
```

You will then find the overlay, ready to copy to a USB stick in the `overlay/` directory.


## How do I use this in production?

Currently, I am using this in Alpine's RAM-based diskless mode. I generate an x86 based Alpine ISO with my custom packages by running `make x86` in the directory for this repo. This will produce an ISO image with all of the additional packages required to make Pinewall work.

I write this to one USB stick using a standard tool like `dd` or `GNOME Disks`, and boot it on an x86 system to be used as a firewall.

At the same time, I also format a second USB stick with the following specs:
* MBR Disk Layout
* One Partition
* EXT4 formatted
* Partition label is `PINECONF` (important! - we use this as a reference in /etc/fstab to allow `lbu commit` to work)

I generate an APK overlay with `make overlay`, and then copy the generated overlay as a file to the `PINECONF` labeled USB stick.

From there, I simply put both sticks into the system I want to use as the router, and I boot it up. The immutable boot environment loads from one stick, and the config loads from the other.

When we make changes inside the live environment, we can save those changes to the secondary stick using:
```
doas lbu commit -dv
```

Until we write our changes to the disk using the above command, **they will not be preserved**. This is in-line with how a lot of networking equipment works because, this way, if you make a change that locks you out of the system, power-cycling the device should get you back to the state you were in before, as the change will not have been committed to disk.

In our case, this command will commit changes to config files to the second USB, which then get loaded on subsequent boots as long as the second USB disk remains connected.

This approach gives us a few benefits:
* A power loss event has a very minimal chance of breaking anything. The disk is only even mounted read-only when we're running the `lbu_commit` command.
* User-error when changing configs has a minimal chance of causing complete lockout. Power-cycling will load the last saved config from disk.
* Running entirely from RAM reduces disk wear and can lower the chance of disk failure.
* To conduct package upgrades or system upgrades, we're able to spin a whole new Pinewall ISO, write it to yet another USB disk and quickly swap it with the disk that has the booted Pinewall ISO on it.
  * This is basically magic because if something breaks, we can just put the older stick back in and everything is back exactly how it was (and working!)
  * And this is basically as close as we're going to get to the container-based microservice idea of machines as "cattle". We don't even update our host, we just spin a whole new base image and deploy that - preserving only our configs in the APKOVERLAY stored on our second USB stick.

And some downsides:
* Streaming data, like logs and bandwidth monitoring data also only gets preserved when you issue an `lbu_commit`, so in a power-loss event this might get lost as it might be a while since you last ran that command.
* We can add new packages on-the-fly if we like - they'll be installed into RAM. **But we need to be careful!** If we want that package to be available again on next boot, we need to spin a new ISO which includes it, otherwise it won't work properly. It will exist in the `/etc/apk/world` file we committed with `lbu_commit`, but Alpine won't be able to actually load and install it during boot, so it might behave unpredictably.
* Some of the above might be mitigated by using Alpine's [Local APK Cache](https://wiki.alpinelinux.org/wiki/Local_APK_cache) feature, but I'm avoiding this deliberately as it adds complexity, and I really like the image-based deployment pattern where I spin a whole new image and replace the stick physically for upgrades.

All things considered I think, for a network appliance deployment, the benefits of running diskless and committing changes to disk only when needed far outweigh the drawbacks that come with needing to spin a new ISO periodically for any packageset changes.
