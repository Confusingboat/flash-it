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

<sup>\*_You will need to move your backups to persistent storage before rebooting or they will be lost_</sup>

### Brief background

This script was born from necessity. I've got a pile of 12G Dell servers that need IT firmware and I wasn't about to flash them all manually. Drives were removed for the first server I flashed, but left in for the subsequent machines to no ill-effect. If you're paranoid, remove them. I tried to make the script with as many safeties as possible since this is such a sensitive process, but it's not perfect, as nothing is.

## Supported hardware
### Tested servers
* R230
* R420
* R720
* R720xd

### Tested adapters
* PERC H310 Mini Monolithic
* PERC H310
* _more coming soon!_

### Untested adapters
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

## Supported Linux distros
### Tested
#### Ubuntu 18.04 (RancherOS 1.5.4 live or installed)
* Just works™
#### Ubuntu 18.04
* Just works™
#### Ubuntu Live 18.04
* You have to get git working; there is an untested fix for this in the `ubuntu-18.04-live-fix` branch
* Alternatively you can try:
  ```
  sudo add-apt-repository ppa:git-core/ppa
  sudo apt-get update
  sudo apt-get install git
  ```
#### Debian Live 10.X.X
* You must add a flag to the kernel on boot, choose to boot to Debian live with C or E and set
  ```
  iomem=relaxed
  ```
* On login install ncurses5
  ```
  sudo apt-get update -y
  sudo apt-get install libncurses5 wget -y
  ```

## How to
### Prerequisites
* Server or other computer with only the target adapter installed and visible to the OS
* Supported Linux distro from above that does not rely on the controller (live environment is recommended)
  * Use others only at your own risk
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

**Don't forget to save your backups.** They will be saved in `/tmp/<your SAS address>` throughout the flashing process; this directory is often emptied every reboot even on installed distros.

## Troubleshooting

### It broke half way through and I want it to work again
Throughout the process, the script echos out what it's about to do. You should be able to figure out how to recover based on where the failure occurred.

For example, if the actual flash hasn't been erased or overwritten, just flash the original SBR back by running `restore_sbr.sh` from the same directory you ran the original `flash-it.sh` script. This should bring your card back to its factory state and allow you to start over.

There is a script for simply flashing back the SBR. This one *is* interactive, but if your backups are still in place you can just leave the inputs blank and the script will find them.

1. `wget https://raw.githubusercontent.com/confusingboat/flash-it/master/restore_sbr.sh`
2. `chmod +x restore_sbr.sh`
3. `sudo ./restore_sbr.sh`

### That didn't work, plz halp

[Here is a guide to recovering a dead card using the lsirec itility.](https://github.com/marcan/lsirec#untested-procedure-to-convert-from-megaraid-to-itir-firmware-or-recover-a-bricked-card)

## Disclaimer

*By downloading and using the scripty bits and associated file(s), you are relinquishing the ability to hold me accountable in any capacity for hardware/software damage or data loss, as well as any moldy pizzas or fruit flies that may manifest in and around your server(s). Use at your own risk.*

## Credit where it is due
The creation of this script would not have been possible without a PDF I found by [/u/fourlynx](https://www.reddit.com/u/fourlynx) or the [lsirec tool](https://github.com/marcan/lsirec) and [other info](https://marcan.st/2016/05/crossflashing-the-fujitsu-d2607/) by [Hector Martin](https://marcan.st/about/).
