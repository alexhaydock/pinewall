# Alpine Linux Homebrew Router - Troubleshooting

### Copying .pcap files to local host

On firewall host:
```sh
doas chown -R mgmt:mgmt /home/mgmt/pcaps
```

On local box:
```sh
scp "mgmt@10.10.10.1:/home/mgmt/pcaps/*.pcap" "$HOME/pcaps/"
```


### Capture 4000 packets to/from a list of hosts on eth1

```sh
doas tcpdump host "1.1.1.2||1.0.0.2" -i eth1 -w ~/pcaps/cloudflare_dns_rsts.pcap -c 4000
```


### Another example that matches a whole CIDR range

```sh
doas tcpdump net "192.168.0.0/24" -i eth0 -w ~/pcaps/facebook_messenger_2.pcap -c 200
```


### A generic example that keeps running until we stop it

```sh
doas tcpdump host 10.2.0.108 -i eth0 -w ~/pcaps/facebook_messenger_3.pcap
```


### Proof of concept to capture various types of unencrypted traffic destined for the WAN
Capturing on `-i any` will let us see the packets as they enter the firewall from the LAN and as they exit to the WAN, allowing us to see which devices are generating the potentially unwanted traffic.

HTTP/DNS/NTP:
(In this example we should see DNS and NTP queries hitting the router but none which leave to the WAN unencrypted)
```
wireshark -k -i <(ssh root@10.10.10.1 -p 22 'tcpdump -i any -n -U -w - port 80\|\|port 53\|\|port 123')
```

HTTP:
```
wireshark -k -i <(ssh root@10.10.10.1 -p 22 'tcpdump -i any -n -U -w - port 80 and dst net not 10.0.0.0/8')
```

DNS:
```
wireshark -k -i <(ssh root@10.10.10.1 -p 22 'tcpdump -i any -n -U -w - port 53 and dst net not 10.0.0.0/8')
```

NTP:
```
wireshark -k -i <(ssh root@10.10.10.1 -p 22 'tcpdump -i any -n -U -w - port 123 and dst net not 10.0.0.0/8')
```


### Capture all traffic from a particular subnet
```
wireshark -k -i <(ssh root@10.10.10.1 -p 22 'tcpdump -i any -n -U -w - net 10.6.0.0/24')
```


### Capture all traffic from a particular host range (gaming devices in my case)
```
wireshark -k -i <(ssh root@10.10.10.1 -p 22 'tcpdump -i any -n -U -w - net 10.6.0.0/24')
```
