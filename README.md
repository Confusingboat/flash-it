# FLASH IT

### The only script you'll need for flashing LSI SAS2-based adapters.

During execution the script will:
* Download and compile all the packages and software it needs
* Download P20 IT mode firmware
* Download boot ROMs
* Backup the current SBR and flash regions from your device
* Backup the SAS and PCI addresses for reference
* Flash modified SBR
* Flash IT firmware
* Flash BIOS/signed UEFI boot ROM
* Sets the original SAS address post-flash to retain multi-adapter support

Just a single reboot is necessary after the script completes.\*

Tested on R320, R420, R720xd with RancherOS 1.5.4 (kernel 4.14) and the Ubuntu 18.04 console, but should work with anything that has bash and apt.

<sup>\*_You will need to move your backups to persistent storage before rebooting or they will be lost_</sup>

### Brief background

This script was born from necessity. I've got a pile of 12G Dell servers that need IT firmware and I wasn't about to flash them all manually. Drives were removed for the first server I flashed, but left in for the subsequent machines to no ill-effect. If you're paranoid, remove them. I tried to make the script with as many safeties as possible since this is such a sensitive process, but it's not perfect, as nothing is.

## Supported Devices
### Tested
* PERC H310 Mini Monolithic
* _more coming soon!_

### Untested
* PERC H310
* PERC H200
* PERC H200e
* IBM M1015
* Other cacheless LSI SAS2x08 cards

### Testing other adapters
Testing adapters that are currently not on the supported list is super easy! Just change the `ADAPTER_PATTERN="H310"` line, where `H310` is a regex pattern that matches your adapter. Please let me know if you test another adapter with success or failure, with the following information:
* Adapter model
* Exact pattern used
* Whether it succeeded or failed
* Other notes about your experience

PRs are also welcome!

## How to
### Prerequisites
* Server or other computer with only the target adapter installed and visible to the OS
* Linux environment with bash and apt that does not rely on the controller (live environment is recommended)
* Internet access from the flashing environment

### Flashing
1. Ensure the adapter you want to flash is the only LSI/Avago/rebranded HBA device in the system.

2. Copy `flash-it.sh` to a directory you're okay with making a mess in:
```
wget https://raw.githubusercontent.com/confusingboat/flash-it/master/flash-it.sh
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

## Disclaimer

*By downloading and using the scripty bits and associated file(s), you are relinquishing the ability to hold me accountable in any capacity for hardware/software damage or data loss, as well as any moldy pizzas or fruit flies that may manifest in and around your server(s). Use at your own risk.*

## Credit where it is due
The creation of this script would not have been possible without a PDF I found by [/u/fourlynx](https://www.reddit.com/u/fourlynx) or the [lsirec tool](https://github.com/marcan/lsirec) and [other info](https://marcan.st/2016/05/crossflashing-the-fujitsu-d2607/) by [Hector Martin](https://marcan.st/about/).
