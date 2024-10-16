## General notes

* By default, recent versions of `unbound` filter queries for `.onion` and do not pass them to upstream resolvers. This is pretty handy for preventing leaks like Brave's recent one (https://www.zdnet.com/article/brave-browser-leaks-onion-addresses-in-dns-traffic/).


## Notes on logging

* Alpine does not include `logrotate` or similar as far as I can see, so anything logging outside of syslog should use its own rotation.
  * By default, Alpine's `syslogd` will rotate `/var/log/messages` every 200KB and keep one single rotated log.
  * This can be changed by editing the `/etc/conf.d/syslog` file.
  * The full list of config options can be found by running `syslogd --help`.
  * I could not find an `unbound.conf` option to rotate logs and for this reason I allow `unbound` to log to syslog (which is the default) instead of to file.
  * In the future I might consider logging `unbound` logs to a separate file and rotating with `logrotate` but I am trying to keep complexity low.


## Notes on conntrack

* You can use `conntrack` (provided by the `conntrack-tools` package) to investigate the connection-tracking layer in the Linux Kernel itself.
* Some interesting `conntrack` commands:
  * `doas conntrack -C` -- Check number of conntrack entries.
  * `doas sysctl net.netfilter.nf_conntrack_max` -- Check the maximum number of conntrack entries.
  * `doas conntrack -E` -- Print a scrolling list of conntrack events as they happen.
  * `doas conntrack -L` -- List the current entries in the conntrack table.


## Notes on rule performance

* With `nftables`, don't worry too much about having a super optimised ruleset. Everything is compiled down to netfilter bytecode when the ruleset is loaded.
* You can see the raw bytecode at the top of the output of:
  * `doas nft --debug=netlink -a list ruleset | less`


## Using unbound-control

* Analyse the state of the server in terms of cache hits and misses and total queries:
  * `doas unbound-control stats_noreset | grep "total.num"`
  * We use `stats_noreset` above because otherwise the stats reset when we run the command.
* We can list our "local zones" with the following:
  * `doas unbound-control list_local_zones`
  * With that above, we should see our defined `transparent` local zone (`localhost.`), and also things like `onion.` and `invalid.` which should never be forwarded upstream.


## Hardware NIC Offload

* NICs are usually capable of offloading various processing features direct to the hardware.
* To get a view of how this is working on your system, try:
  * `doas ethtool -k eth1`


## Investigating current DHCP leases

* You can check the currently allocated DHCP leases with:
  * `less /var/lib/kea/dhcp4.leases`


## Upgrading Alpine

* To upgrade the system:
  * `doas apk update && doas apk upgrade`
* If we upgrade Alpine to a new point release, we should make sure to check the Release Notes for the specific release:
  * https://wiki.alpinelinux.org/wiki/Release_Notes_for_Alpine_3.15.0
* Commit notes for upgraded packages in `main` repo.
  * So there aren't super detailed release notes for each package release, but the packages move slowly enough that you can generally track everything in `main` by running a search on the Alpine `abuild` repo:
  * https://git.alpinelinux.org/aports/log/?qt=grep&q=main%2F


## System Auditing with APK

* APK is pretty amazing in that you can basically use it as a HIDS as it will allow you to compare your system against the package database defaults.
* For a generic audit comparing configuration files against the package db:
  * `apk audit --backup --check-permissions | less`
* For an audit of system files:
  * `apk audit --system --check-permissions | less`


## Other APK Stuff

* You can check the stats of installed packages with:
  * `apk stats`
* Finally, you can list installed packages with:
  * `apk list --installed | less`
