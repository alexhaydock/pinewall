## TODO

## TODO: More complex logging

In its default state, the `nftables` `log` option will log information about a triggered rule to the kernel ring buffer (so we can read it via `dmesg`). There seems to be methods of doing this in a more complex way, such as by using `NFLOG` to feed to `ulogd`.

I think, using these more complex methods, we can write out full actual packets to the log meaning we can effectively have a 24/7 `.pcap` running that only matches on dropped traffic or where our rules trigger. This can be super useful for a whole host of reasons so I'm definitely looking into this for the future.


## Quick Note on lbu

```sh
doas LBU_BACKUPDIR="/home/mgmt/backup" lbu commit -dv
```
