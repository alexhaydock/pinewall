# Alpine Linux Homebrew Router - Build Guide

> WARNING: The following instructions are from an older version of this project which started with a blank manual Alpine `sys` disk install and explained how to bring that environment to a fully-working router state. The Pinewall project has since evolved beyond this, and build scripts are now used instead, to generate fully functional generic `x86_64` and Raspberry Pi `aarch64` builds.

## Initial Install (VGA / Console)
These steps are to be performed directly on the target machine.

* Boot the Alpine Linux ISO on the target system.
* Log into the live system as `root` and start the installer with `setup-alpine`.
* Select your keyboard map and choose a hostname.
* When prompted to configure a network interface, enter the name of the interface you want to use as the upstream WAN interface.
  * This is `eth1` in my case but it might vary.
* Enter `dhcp` if your upstream WAN provider issues IP addresses via DHCP.
* Now enter the name of the interface you will use as the downstream LAN interface.
* Enter the IP address this router will use for untagged (VLAN 0) packets on this interface, e.g. `192.168.200.1`
* Enter `none` when asked what gateway you want to use for this interface (we _are_ going to be the gateway in this case).
* Choose `UTC` (default) as your timezone.
* Choose `chrony` (default) as the NTP client.
* Choose a reliable package mirror (I pick 25 - `ftp.acc.umu.se`)
* Chose `openssh` (default) as the SSH server to use.
* Enter the name of the disk to install to (e.g. `sda`)
* Enter `sys` to perform a traditional disk-based system install.
* Once the install has completed, perform a `sync && sync && reboot` to reboot into our new system.

### Create Non-Root Management User
* Log into the new system using `root` and the password you chose during install.
* Install sudo:
  * `apk --no-cache add sudo`
* Grant members of the `wheel` group `sudo` access:
  * `echo '%wheel ALL=(ALL) ALL' > /etc/sudoers.d/wheel`
* Add a new user to manage the system with:
  * `adduser -h /home/mgmt -s /bin/ash mgmt`
  * N.B. You can choose `/bin/bash` as the user shell if desired, but you will need to install it with `apk --no-cache add bash`
* Add the new user to the wheel group:
  * `adduser mgmt wheel`
* Allow only the new user to log in via SSH:
  * `echo 'AllowUsers mgmt' | tee -a /etc/ssh/sshd_config`
  * `echo 'PasswordAuthentication yes' | tee -a /etc/ssh/sshd_config`
  * `rc-service sshd restart`

### Prepare SSH to Bootstrap Remainder of Config
These steps are to be performed to allow us to move towards using SSH to configure the rest of the system.

* On the LAN client you wish to use for SSH, set up a static IP within the same subnet that you chose for VLAN 0 earlier.
  * In my example which gave the Alpine Router an IP of `192.168.200.1`, I will configure my LAN client with an IP of `192.168.200.10`
* Connect the client to the port on the Alpine Router you configured to be used for LAN purposes.
* Log into SSH from the client using your management username and the gateway IP:
  * `ssh mgmt@192.168.200.1`

## Steps to Perform over SSH
These steps are to be performed over SSH. You could do these from the console technically, but they will involve copying in large config files so I can't recommend it.

### Install Packages
* Install Alpine Router package-set:
  * Core functionality:
    * `sudo apk --no-cache add dhcp-server-vanilla nftables sudo unbound vlan`
  * Optional functionality:
    * `sudo apk --no-cache add avahi conntrack-tools dbus ethtool htop iperf3 nano nload tcpdump vnstat wireguard-tools-wg`

### Configure and enable VMware Tools (optional)
* If using VMware to host or test this router:
  * `sudo nano /etc/apk/repositories`
  * And uncomment the community repository line to enable it.
  * `sudo apk --no-cache add open-vm-tools open-vm-tools-guestinfo open-vm-tools-deploypkg`
  * `sudo rc-service open-vm-tools start`
  * `sudo rc-update add open-vm-tools`

### Configure VLANs / network interfaces
* Install network interface config:
  * `sudo nano /etc/network/interfaces`

### Configure and enable DHCP Server
* Ensure `dhcpd` starts with the system:
  * `sudo rc-update add dhcpd`
* Remember to add our dhcpd config:
  * `sudo nano /etc/dhcp/dhcpd.conf`
* At this point **(optional)** if your `dhcpd.conf` is fully populated, you should be able to reconfigure your LAN client and reboot the Alpine Router and your LAN client should pull an IP address from the DHCP range configured in the `dhcp.conf` for the router.
  * This would be a good time to test this, before we go any further and start adding firewall rules.

### Configure system for routing
* Ensure that the kernel options allowing routing are configured by placing the `/etc/sysctl.d/local.conf` file from this repo in the right place.
* Rebooting after adding this file will make sure it takes effect.

### Configuring firewall rules with nftables
* Ensure that `/etc/nftables.nft` from this repo is in the correct place on the router.
* Ensure that all of the files from `/etc/nftables.d/` are in the correct place on the router.
* Make the `nftables` rules executable so they can be applied atomically:
  * `sudo chmod +x /etc/nftables.nft`
* Apply the new rules and cross your fingers that nothing breaks:
  * `sudo /etc/nftables.nft`
* Ensure that `nftables` loads our rules on boot:
  * `sudo rc-update add nftables`

### Configuring DNS-over-TLS forwarding resolver with unbound
* Install `unbound`:
  * `sudo apk --no-cache add unbound`
* Install `unbound.conf` from this repo:
  * `sudo nano /etc/unbound/unbound.conf`
* Enable and start `unbound`:
  * `sudo rc-service unbound start`
  * `sudo rc-update add unbound`

### Configure NTP server with chronyd
* `chronyd` is installed by default as part of the base Alpine install.
* If we are on Alpine 3.13 and we want to use NTS with `chrony`, we need the newest version of the package.
* We can install this with `sudo apk update && sudo apk add chrony@edge`
* Install our custom config:
  * `sudo nano /etc/chrony/chrony.conf`
* Restart `chronyd`:
  * `sudo rc-service chronyd restart`
* Check status with:
  * `sudo chronyc -N sources`
  * `sudo chronyc -N authdata`  # If we're using NTS

### Configure and enable TFTP server for booting PXE clients (optional)
* `sudo apk --no-cache add tftp-hpa`
* `sudo rc-update add in.tftpd`
* `sudo rc-service in.tftpd start`

### Configure and enable nginx to cache content for PXE clients (optional)
* `sudo apk --no-cache add nginx`
* `sudo rc-update add nginx`
* `sudo rc-service nginx start`
* Add the config in this repo into `/etc/nginx/http.d/default.conf` to act as a reverse proxy for `www.mirrorservice.org` caching a maximum of `100GB` into `/var/cache/nginx`.

### Functional Router
* At this point, if you did everything correctly and (mainly) if your `nftables` rules and `dhcpd` configs are correct, then you should pretty much have a fully functional router/gateway platform that provides routing, firewalling, DHCP, DNS, and NTP.
* Anything beyond this point is optional.

### Configure and enable SSH Keypair Authentication (optional, recommended!)
* Configure a new SSH public/private keypair on your workstation:
  * `ssh-keygen -t ed25519 -C "Alpine Router" -f ~/.ssh/id_ed25519_AlpineRouter`
  * You can choose to enter a passphrase but we can have some easier fun with Wireshark if you don't.
* Copy the keypair to the remote host:
  * `ssh-copy-id -i ~/.ssh/id_ed25519_AlpineRouter mgmt@10.10.10.1`
* Edit your local SSH config (`~/.ssh/config`) to make sure the key is always used for this host.
* Once you have confirmed that you can log into your remote host automatically and without needing to type a password (`ssh mgmt@10.10.10.1`), we can perform our Wireshark magic (see the scripts inside `wireshark-magic/`).

### Allowing root SSH for Wireshark fun (optional)
* If you want to `tcpdump` over SSH, you should enable the root account and use only a passkey for authentication.
* Copy our `authorized_keys` file over to the root account:
  * `sudo mkdir /root/.ssh`
  * `sudo chmod 2700 /root/.ssh`  # Based on the default that Alpine creates `~/.ssh` with.
  * `sudo cp -fv /home/mgmt/.ssh/authorized_keys /root/.ssh/authorized_keys`
  * `sudo chmod 0600 /root/.ssh/authorized_keys`
* Allow `root` login with SSH keypairs:
  * `sudo nano /etc/ssh/sshd_config`
* Ensure the lines below are listed:
```
AllowUsers mgmt root
PermitRootLogin prohibit-password
```
* And then restart `sshd`:
  * `sudo rc-service sshd restart`

### Configure and enable iperf3 (optional)
* Install iperf3:
  * `sudo apk --no-cache add iperf3`
* Create a new user that will run `iperf3`:
  * `sudo adduser -H -s /sbin/nlogin -D -S -u 667 -g "iperf user" iperf`
* Edit the `iperf3` init.d file that the `iperf3` package pulled in so it will run with our unprivileged user:
  * `sudo nano /etc/init.d/iperf3`
  * Add the following line in between the `supervisor=` and `command=` lines:
  * `: ${command_user:="iperf:nogroup"}`
  * A full copy of this file is stored in `/etc/init.d` in this repo.
* Start and enable `iperf3`:
  * `sudo rc-service iperf3 start`
  * `sudo rc-update add iperf3`

### Configure and enable WireGuard client (optional)
* Install WireGuard:
  * `sudo apk --no-cache add wireguard-tools-wg`
* Copy our WireGuard config over (notice we have trimmed it to just a few options):
  * `sudo mkdir /etc/wireguard`
  * `sudo nano /etc/wireguard/wg0.conf`
```
[Interface]
PrivateKey = xijaxoijasoimadoiasdoismdoimsadoimsadimosad=

[Peer]
PublicKey = aomdposamdposakdposakdposakdpokdposad=
Endpoint = 1.2.3.4:51820
AllowedIPs = 0.0.0.0/0
```
* Notice that we've trimmed quite a bit here compared to when we use `wg-quick` on a system.
  * We don't specify our `Address` in the `[Interface]` stanza, or our `DNS`. These are both things for `wg-quick`.
* Instead, we define our address in the `/etc/network/interfaces` file (our WireGuard client address and netmask go here):
```
auto wg0
iface wg0 inet static
    address 10.9.45.10
    netmask 255.255.255.0
    pre-up ip link add dev wg0 type wireguard
    pre-up wg setconf wg0 /etc/wireguard/wg0.conf
    post-down ip link delete dev wg0
```
* After defining all of the above, we can bring up our interface with:
  * `sudo ifup wg0`
* And we can check with:
  * `sudo wg show`
* We can check that our tunnel is working by pinging the WireGuard gateway.
  * In our case, this would be: `ping 10.9.45.1`
  * We could also ping other device we know are on the same WireGuard subnet.
* We can also check that a route has been added for the WireGuard subnet with `ip route`.
* If our pings work fine, then our tunnel is successful!

### Configure and enable vnStat (optional)
* Edit the APK repos file:
  * `sudo nano /etc/apk/repositories`
  * And uncomment the community repository line to enable it.
* Now install `vnstat`:
  * `sudo apk --no-cache add vnstat`
* Restrict `vnstat` to just our WAN interface:
  * `sudo sed -i 's/^Interface ""/Interface "eth1"/g' /etc/vnstat.conf`
* Start and enable `vnstat`:
  * `sudo rc-service vnstatd start`
  * `sudo rc-update add vnstatd`
* After waiting a while for the database to populate, we can view our stats with a simple:
  * `vnstat`

### Enabling more complex logging with nftables (optional, WIP)
By default, these logs get fed to the kernel log and can be read with `dmesg`. We can do more complex things to get them onto disk though.

* Install `ulogd`:
  * `sudo apk --no-cache add ulogd`
* Start and enable the service:
  * `sudo rc-service ulogd start`
  * `sudo rc-update add ulogd`

### Enabling Avahi to proxy mDNS/Bonjour/AirPlay/etc between VLANs (optional)
* Install `avahi`:
  * `sudo apk --no-cache add avahi dbus`
* Configure config **(be careful to set the allow-interfaces and deny-interfaces correctly for your network)**:
  * `sudo nano /etc/avahi/avahi-daemon.conf`
* Start and enable Avahi service:
  * `sudo rc-service avahi-daemon start`
  * `sudo rc-update add avahi-daemon`
* Install Avahi Tools on your local machine and check things are working:
  * `sudo dnf install avahi-tools`
  * `avahi-browse --all --verbose --terminate`
