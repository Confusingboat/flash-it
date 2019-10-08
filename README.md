# FLASH IT
Easy one-step flashing for H310 Mini Monolithic adapter; the small one that goes into the special slot on the motherboard of Dell 12th Generation servers. Can probably be applied to similar devices with the proper SBR config file and script variable changes (device identification).

Tested on RancherOS with Ubuntu console, but should work with anything that has bash and apt.

## Brief background

This script was born from necessity. I've got a pile of 12G Dell servers that need IT firmware and I wasn't about to flash them all manually. Drives were removed for the first server I flashed, but left in for the subsequent machines to no ill-effect. If you're paranoid, remove them. I tried to make the script with as many safeties as possible since this is such a sensitive process, but it's not perfect, as nothing is.

*By downloading and using the scripty bits and associated file(s), you are relinquishing the ability to hold me accountable in any capacity for hardware/software damage or data loss, as well as any moldy pizzas or fruit flies that may manifest in and around your server(s). Use at your own risk.*

## What exactly does this thing do

It really does it all. During execution the script downloads and compiles all the packages and software it needs, backs up the current SBR and flash regions from your device (as well as the SAS and PCI addresses for reference), flashes the new SBR, IT firmware, BIOS/UEFI boot ROMs, and sets back the original SAS address. Just a single reboot is necessary after the script completes.

## Prerequisites
* 12th Gen Dell server (R320, R420, R720xd, etc) with a completely stock H310 Mini Mono adapter
* Working Linux environment with bash and apt that does not rely on the controller (live environment is preferred)
* Internet access from the flashing environment

## How to
1. Ensure the adapter you want to flash is the only LSI/Avago/rebranded HBA device in the system.

2. Copy `flash-it.sh` and `H310MM_mod.cfg` to a directory you're okay with making a mess in:
```
wget https://raw.githubusercontent.com/Confusingboat/flash-it/master/flash-it.sh
wget https://raw.githubusercontent.com/Confusingboat/flash-it/master/H310MM_mod.cfg
```
3. Make the script executable:
```
chmod +x flash-it.sh
```

4. Make it go:
```
sudo ./flash-it.sh
```

**Don't forget to save your backups.** They will be saved in `/tmp/<your SAS address>` throughout the flashing process.

## Troubleshooting

### It broke half way through and I want it to work again
If the actual flash hasn't been erased or overwritten, just flash the original SBR back by running `restore_sbr.sh` from the same directory you downloaded the other two files into.

This one *is* interactive, but if your backups are in place you can just leave the inputs blank.

1. `wget https://raw.githubusercontent.com/Confusingboat/flash-it/master/restore_sbr.sh`
2. `chmod +x restore_sbr.sh`
3. `sudo ./restore_sbr.sh`

## Credit where it is due
The creation of this script would not be possible without a PDF I found by [/u/fourlynx](https://www.reddit.com/u/fourlynx) or the [lsirec tool](https://github.com/marcan/lsirec) and [other info](https://marcan.st/2016/05/crossflashing-the-fujitsu-d2607/) by [Hector Martin](https://marcan.st/about/).
