```

     /\ /\          ____  _                          _ _ 
    // \  \        |  _ \(_)_ __   _____      ____ _| | |
   //   \  \       | |_) | | '_ \ / _ \ \ /\ / / _' | | |
  ///    \  \      |  __/| | | | |  __/\ V  V / (_| | | |
  //      \  \     |_|   |_|_| |_|\___| \_/\_/ \__'_|_|_|
           \
  
       A minimal Alpine Linux home Firewall / Router.


```


> WARNING: The project in this repo is not yet considered "production-ready". Use at your own risk.


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
* Be free of unnecessary complexity and attack surface (GUIs etc)
* Be minimal and simple to manage
* Be easy to back up and migrate config
* Be crash safe and resiliant to power loss (we will need to run mainly from RAM)


## Who is this for?

Me.

This project is designed to be minimal and simple. The downside of this is that it may be slightly rigid in terms of conforming to my needs. If I don't need something, I didn't include it.

That said, I've tried my best to document everything as thoroughly as possible and I'm using this public repo as my actual development workspace for the live version of Pinewall that I'm running in production at home. The hope there is that the code and processes in use here may benefit others who wish to opt for a similar setup.

I'm also very willing to help out generally where I can if people get stuck (feel free to open issues) or want to try and implement something new on top of this. The best way to learn is through experimenting and trying to solve problems. I'm also open to sensible suggestions via PR that make the project a bit more adaptable to the needs of others (but without compromising the goals of simplicity and minimalism!).


## Feature matrix

| Feature                           | Alpine Package      | Alpine Repo | Notes            |
|-----------------------------------|---------------------|-------------|------------------|
| Firewall                          | nftables            | main        | Working          |
| 802.1Q VLANs                      | ifupdown-ng         | main        | Working          |
| DHCP Server                       | dhcp-server-vanilla | main        | Working          |
| DHCP Reservations                 | dhcp-server-vanilla | main        | Working          |
| DNS Server (Upstream via DoT)     | unbound             | main        | Working          |
| DNSSEC                            | unbound             | main        | Working          |
| DNS Cache                         | unbound             | main        | Working          |
| NTP Server                        | chronyd             | main        | Working          |
| Port Forwarding (Destination NAT) | nftables            | main        | Working          |
| Performance Testing               | iperf3              | main        | Working          |
| VPN (Client only, no routing)     | wireguard-tools-wg  | main        | Working          |
| Static Port NAT for Games         | nftables            | main        | Working          |
| Remote Wireshark                  | tcpdump             | main        | Working          |
| Bandwidth Monitoring              | vnstat              | community   | Working          |
| mDNS Proxy                        | avahi, dbus         | main        | Working          |
| TFTP Server (for PXE clients)     | tftp-hpa            | main        | Working          |
| Caching Proxy (for PXE clients)   | nginx               | main        | Working          |
| Log Shipping                      | Splunk UF           | not in repo | Not started      |
| UPnP Daemon                       | miniupnpd           | community   | Rejected`*`      |

`*` The `miniupnpd` 2.1 stable release shipped by Alpine 3.13 is not yet compatible with `nftables`, though upstream has been working on this support for a while and it seems to be planned for the 2.2 branch. I'll revisit this when Alpine start shipping `miniupnpd` 2.2+.

## Every package added on top of the Alpine "Standard" profile by Pinewall

Below you can find a list of every package installed on top of the Alpine "Standard" profile. You can find these defined in this repository inside `mkimg.pinewall.sh` (which includes the packages in our custom Alpine image), and inside `genapkovl-pinewall.sh` which is an APK overlay which ensures that the packages are installed into RAM and available when the live system boots.

| Package             | Repo      | Functionality         |
|---------------------|-----------|-----------------------|
| avahi               | main      | optional              |
| conntrack-tools     | main      | optional              |
| dbus                | main      | dependency (of avahi) |
| dhcp-server-vanilla | main      | core                  |
| ethtool             | main      | optional              |
| htop                | main      | optional              |
| iperf3              | main      | optional              |
| nano                | main      | optional              |
| nftables            | main      | core                  |
| nginx               | main      | optional              |
| nload               | main      | optional              |
| sudo                | main      | core                  |
| tcpdump             | main      | optional              |
| tftp-hpa            | main      | optional              |
| unbound             | main      | core                  |
| vnstat              | community | optional              |
| wireguard-tools-wg  | main      | optional              |


## What doesn't work?

* `nftables` logging to disk
  * Currently the `log` option works in nftables rules, but the logs just end up in the kernel ring buffer (can be read with `dmesg` though).
  * We can log much more robustly (including full packet contents) if we install and configure `ulogd2`.
  * See: https://blog.grimmo.it/2016/05/05/iptables-logging-using-nflog-and-ulogd2-on-debian-jessie/
* UPnP
  * The main package that seems to be used for this (and the same one pfSense uses), `miniupnpd`, doesn't have a stable release that supports `nftables` yet. 
* IPv6
  * I can't really test this since my upstream ISP doesn't actually support it yet :(
* PPPoE
  * Again, due to my upstream ISP being DOCSIS rather than VDSL/G.Fast, I have no means of testing a PPP link.
* Log monitoring and alerting
  * I haven't really decided on my solution for this yet, but it'll probably end up being the Splunk Universal Forwarder feeding the logs from `/var/log` into a remote Splunk Enterprise instance.
