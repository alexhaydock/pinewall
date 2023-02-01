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

| Feature                             | Alpine Package        | Alpine Repo | Notes            |
|-------------------------------------|---------------------  |-------------|------------------|
| 802.1Q VLANs                        | ifupdown-ng           | main        | Working          |
| DHCPv4 Reservations                 | dhcp-server-vanilla   | main        | Working          |
| DHCPv4 Server                       | dhcp-server-vanilla   | main        | Working          |
| DNS Cache                           | unbound               | main        | Working          |
| DNS Root Hints (for Unbound)        | dns-root-hints        | main        | Working          |
| DNS Server (Upstream via DoT)       | unbound               | main        | Working          |
| DNSSEC                              | unbound               | main        | Working          |
| Firewall                            | nftables              | main        | Working          |
| IPv6 Router Advertisements          | radvd                 | main        | Working          |
| mDNS Proxy                          | avahi, dbus           | main        | Working          |
| NTP Server                          | chronyd               | main        | Working          |
| Performance Testing                 | iperf3                | main        | Working          |
| Port Forwarding (Destination NAT)   | nftables              | main        | Working          |
| PPPoE Connectivity                  | ppp-pppoe             | main        | Working          |
| PPPoE integration with ifupdown     | ifupdown-ng-ppp       | main        | Working          |
| Privilege Escalation                | doas                  | main        | Working          |
| Remote Wireshark                    | tcpdump               | main        | Working          |
| WireGuard integration with ifupdown | ifupdown-ng-wireguard | main        | Working          |
| WireGuard VPN Server                | wireguard-tools-wg    | main        | Working          |
| Log Shipping                        | Splunk UF             | not in repo | Not started      |


## Supported Deployments

* Raspberry Pi 4 / Compute Module 4
  * This is the main target platform, as it's what I actively deploy. This is where you can expect development, support, and prompt fixes for issues.
  * I will likely try and support new Pi revisions as they release, but nothing before the Pi 4 will be supported as previous revsions do not use a proper ethernet controller and are not capable of routing at gigabit speeds.
* Generic x86_64 PC
  * Supported only on a best-effort basis and no longer automatically built by the GitLab CI processes.


## Every package added on top of the Alpine "Standard" profile by Pinewall

Below you can find a list of every package installed on top of the Alpine "Standard" profile. You can find these defined the `apks` variable inside either `mkimg.pinewall_x86.sh`, or `mkimg.pinewall_rpi.sh`.

| Package             | Repo      | Functionality         |
|---------------------|-----------|-----------------------|
| avahi                 | main      | optional              |
| chrony                | main      | optional              |
| conntrack-tools       | main      | optional              |
| dbus                  | main      | dependency (of avahi) |
| dhcp-server-vanilla   | main      | core                  |
| dns-root-hints        | main      | core                  |
| doas                  | main      | core                  |
| ethtool               | main      | optional              |
| htop                  | main      | optional              |
| ifupdown-ng-ppp       | main      | core                  |
| ifupdown-ng-wireguard | main      | optional              |
| iperf3                | main      | optional              |
| nano                  | main      | optional              |
| nftables              | main      | core                  |
| nload                 | main      | optional              |
| ppp-pppoe             | main      | core                  |
| radvd                 | main      | core                  |
| tcpdump               | main      | optional              |
| unbound               | main      | core                  |
| wireguard-tools-wg    | main      | optional              |


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

To build the Raspberry Pi image (`pinewall.img`) run:
```bash
make image
```


## How do I use this in production?

_Update to this section coming soon._
