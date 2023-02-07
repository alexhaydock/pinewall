![Pinewall Logo](logo.png)

# Pinewall
A minimal Alpine Linux home firewall / router.

## Introduction
There's some controversy right now (March 2021) around Netgate and pfSense and I have been looking to explore alternatives for a while. I could jump ship to OPNSense, but it's based on FreeBSD just like pfSense and [FreeBSD's code quality is being called into question too](https://arstechnica.com/gadgets/2021/03/buffer-overruns-license-violations-and-bad-code-freebsd-13s-close-call/) at the moment.

Linux also seems to have the better networking stack these days (which Netgate seem to be well aware of as they base [their extremely high performance TNSR router](https://www.tnsr.com/) platform on Linux rather than BSD). You also get to [play with eBPF and XDP Hardware Offload](https://blog.cloudflare.com/how-to-drop-10-million-packets/) if you're lucky enough to have compatible gear.

If I had to pick a proper vendor-supported Linux-based routing platform to use, I would probably pick [VyOS](https://vyos.io/), the still-developed OSS fork of Brocade's Vyatta. But hey -- a home or SoHO firewall/gateway device is actually pretty a pretty simple set of features -- why not just build one from scratch? That idea became this project.

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
* Have first-class IPv6 support

## Who is this for?
Me.

This project is designed to be minimal and simple. The downside of this is that it may be slightly rigid in terms of conforming to my needs. If I don't need something, I didn't include it.

Pinewall is also quite opinionated. It is designed from the ground-up to treat IPv6 as the primary target version of IP, with IPv4 support being provided on a best-effort basis. For this reason, many technologies associated with IPv4 are mostly ignored here (Inbound NAT Port Forwarding, Static Port Outbound NAT, UPnP). Pinewall is fully geared-up to support IPv6-only and IPv6-mostly networks, as this is how I deploy it in production.

That said, I've tried my best to document everything as thoroughly as possible and I'm using this public repo as my actual development workspace for the live version of Pinewall that I'm running in production at home. The hope there is that the code and processes in use here may benefit others who wish to opt for a similar setup.

I'm also very willing to help out generally where I can if people get stuck (feel free to open issues) or want to try and implement something new on top of this. The best way to learn is through experimenting and trying to solve problems. I'm also open to sensible suggestions via PR that make the project a bit more adaptable to the needs of others (but without compromising the goals of simplicity and minimalism!).

## Is this a custom distro / is this a fork of Alpine?
Not really.

This is more of a set of scripts and configs that allows you to compose a custom Alpine Linux image that contains all the additional packages needed to run a Linux-based home router on a Raspberry Pi. Most of this is built around the native 'overlay' functionality provided by Alpine's [local backup utility](https://wiki.alpinelinux.org/wiki/Alpine_local_backup) - I've just tailored it specifically towards being a home router.

## What hardware does Pinewall support?
* Raspberry Pi 4 / Compute Module 4
  * This is the main target platform, as it's what I actively deploy. This is where you can expect development, support, and prompt fixes for issues.
  * I will likely try and support new Pi revisions as they release, but nothing before the Pi 4 will be supported as previous revsions do not use a proper ethernet controller and are not capable of routing at gigabit speeds.
* Generic x86_64 PC
  * Supported only on a best-effort basis and no longer automatically built by the GitLab CI processes.

## What packages does Pinewall add on top of a standard Alpine Linux base?
Here you can find a list of every package that Pinewall installs on top of the Alpine "Standard" profile, along with the justifcation for each package's presence.

You can find these packages defined in the `apks` variable inside either `mkimg.pinewall_x86.sh`, or `mkimg.pinewall_rpi.sh`.

| Package               | Repo | Functionality                                                                          |
|-----------------------|------|----------------------------------------------------------------------------------------|
| avahi                 | main | Multicast DNS proxy for relaying mDNS trafic across VLANS                              |
| chrony                | main | NTP Client & Server                                                                    |
| conntrack-tools       | main | Allows introspecting the kernel's conntrack table(s)                                   |
| dbus                  | main | Dependency (of avahi)                                                                  |
| dhcp-server-vanilla   | main | ISC DCHPv4 Server                                                                      |
| dns-root-hints        | main | Provides DNSSEC root keys for Unbound                                                  |
| doas                  | main | Privilege escalation, similar to sudo                                                  |
| dropbear              | main | Minimal SSH server, similar to OpenSSH                                                 |
| ethtool               | main | Allows inspecting/configuring physical network interfaces                              |
| htop                  | main | System performance viewer                                                              |
| ifupdown-ng-ppp       | main | PPP connection integration with /etc/network/interfaces                                |
| ifupdown-ng-wireguard | main | WireGuard connection integration with /etc/network/interfaces                          |
| iperf3                | main | Network performance testing                                                            |
| logrotate             | main | Allows for automatic rotation of system logs                                           |
| nano                  | main | Text editor                                                                            |
| nftables              | main | Firewall                                                                               |
| nload                 | main | Network throughput viewer                                                              |
| pinehole.sh           | N/A  | Minimal Pinewall-focused implementation of just the adblock functionality from Pi-Hole |
| ppp-pppoe             | main | The main PPP daemon for dialing PPPoE connections                                      |
| radvd                 | main | IPv6 Router Advertisement daemon                                                       |
| raspberrypi           | main | Raspberry Pi support tools and scripts                                                 |
| rng-tools             | main | Random number generator daemon, especially useful for Raspberry Pi systems             |
| tcpdump               | main | Packet capturing                                                                       |
| unbound               | main | Recursive DNS resolver (with caching and filtering)                                    |
| wireguard-tools-wg    | main | Just enough WireGuard to set up WireGuard connections without also pulling in iptables |

## What doesn't work yet?
* IPv6 ruleset for nftables
  * My production config for this is very functional, but I'm fully aware that the one in this repository needs a lot of work to be functional and useful. For obvious reasons, the configs in this repo are just examples rather than the full configs I run in production complete with my entire firewall layout and PPPoE passwords and such. Regrettably, this means they get a lot less attention than the ones I've actually got running in production.
  * For the time being, I'd recommend for now which shows off a good IPv6 nftables ruleset would be [this post on the Alpine wiki](https://wiki.alpinelinux.org/wiki/Linux_Router_with_VPN_on_a_Raspberry_Pi_(IPv6)#nftables).
* DHCPv6
  * Pinewall does not currently support DHCPv6 as either a server or a client.
  * I'm fortunate enough to have a very forward-thinking ISP (shout-out to [AAISP](https://www.aa.net.uk/) in the UK) who routes a static IPv6 `/48` to me. I just pick static `/64` ranges from this allocation and assign them to my VLANs, rather than needing to deal with prefix delegation from upstream. For this reason, I haven't bothered including it in Pinewall.
* Log monitoring and alerting
  * I haven't really decided on my solution for this yet, but I'll probably end up using rsyslog with some janky output formatting to feed directly to a Splunk HTTP Event Collector (HEC) endpoint.

## Why Alpine Edge rather than the latest stable release?
This is mostly down to the fact that the Linux kernel package for Raspberry Pi seems to update more rapidly than in the stable branch, though I cant say that this is entirely consistent. But I've had no problems so far running with Edge so I've decided to stick with that approach.

## How can I download this?
You can download built Raspberry Pi 4 images from the Pinewall GitLab Package Registry [here](https://gitlab.com/pinewall/pinewall/-/packages), where they are built weekly on Saturdays by a scheduled CI/CD run.

## How can I build this locally instead?
Install Podman and the `qemu-user-static` to allow for cross-compilation (assuming you're not already running an `aarch64` system):
```sh
sudo apt install podman qemu-user-static
```

To build the Raspberry Pi image (`pinewall.img.gz`) run:
```bash
make image
```

This will output the built `pinewall.img.gz` into the current directory.

## How can I use this in production?
Well the way _I_ run this in production is to use the exact images that the GitLab CI process builds and pushes to the Package Registry. I use Raspberry Pi Imager to write the `pinewall.img.gz` file directly to a microSD card.

I then have a second repo which contains a fork of the contents of the `config/` directory found in this repo, where I can add things that I can't publish to this repo, like my WireGuard host keys and config, and my PPP dialing passwords. That repo uses GitLab CI to build an APKOVERLAY file (using a similar `genapkovl-pinewall.sh` script to the one in this repo). I simply drop the built APKOVERLAY onto the microSD card I just flashed the fresh Pinewall image to and put it in my Raspberry Pi.

I keep a rotation of 2 microSD cards going for this, meaning that I never make changes to the current running deployment. Changes are always written to a new microSD card, and then I swap in the new card, taking the old card out. This means that if a new Pinewall image (or a new config change I've made in the overlay) causes a problem, I always have a way to roll back to the known-working config simply by putting in the previous microSD card.

Similarly, I make an effort to make all configs as generic as possible so that they're not specific to the Pi's hardware (so no using IPv6 EUI-64 addresses that depend on the hardware MAC address, or other such things). This means that if my router/gateway fails, I can simply put the microSD card into a different Raspberry Pi 4 and boot it up and _boom_ - enterprise(-ish) redundancy at a fraction of th cost.

This is about as close as I can get to atomic container-style update (and the sysadmin's dream of treating all hosts as cattle rather than pets) with a home-grown firewall/gateway solution.

## How can I add my own configs to this?
The easiest method will just be to fork it here on GitLab and start changing things in the `config/` directory as you please. As a bonus, if you fork it here you'll get the benfits of the automatic CI/CD processes building images for you - even if you're using a free GitLab.com account. Try it out!
