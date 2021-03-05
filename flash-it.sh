#!/bin/bash

# Must be run as root
[[ $EUID > 0 ]] && echo "Error: must run as root/su" && exit 1

MEGACLI_URL="https://docs.broadcom.com/docs-and-downloads/raid-controllers/raid-controllers-common-files/8-07-14_MegaCLI.zip"
LSIUTIL_URL="https://github.com/confusingboat/meta-xa-stm/raw/master/recipes-support/lsiutil/files/lsiutil-1.72.tar.gz"
LSIREC_REPO_URL="https://github.com/confusingboat/lsirec"
FIRMWARE_BIOS_URL="https://docs.broadcom.com/docs-and-downloads/host-bus-adapters/host-bus-adapters-common-files/sas_sata_6g_p20/9211-8i_Package_P20_IR_IT_FW_BIOS_for_MSDOS_Windows.zip"
UEFI_URL="https://docs.broadcom.com/docs-and-downloads/host-bus-adapters/host-bus-adapters-common-files/sas_sata_6g_p20/UEFI_BSD_P20.zip"

MEGACLI_FILE_NAME="megacli.zip"
LSIUTIL_FILE_NAME="lsiutil.tar.gz"
FIRMWARE_PACKAGE_FILE_NAME="firmware.zip"
UEFI_PACKAGE_FILE_NAME="uefi.zip"

BACKUP_ROOT_DIR="/tmp"

ADAPTER_PATTERN="H310|H200|M1015"
ADAPTER_INDEX="0"
#SBR_CFG_MODIFIED_FILE_PATH="H310MM_mod.cfg"
FIRMWARE_UNPACK_DIR="/tmp/lsi_firmware"
UEFI_UNPACK_DIR="/tmp/lsi_uefi"
FIRMWARE_FILE_NAME="2118it.bin"
BIOS_FILE_NAME="mptsas2.rom"
UEFI_FILE_NAME="x64sas2.rom"

FIRMWARE_FILE_PATH="$(find ${FIRMWARE_UNPACK_DIR} -name ${FIRMWARE_FILE_NAME})"
BIOS_FILE_PATH="$(find ${FIRMWARE_UNPACK_DIR} -name ${BIOS_FILE_NAME})"
UEFI_FILE_PATH="$(find ${UEFI_UNPACK_DIR} -name ${UEFI_FILE_NAME} | grep Signed)"

function wait_for_ioc {
  local c=0
  echo
  echo -n "Waiting for IOC to become ready..."
  while ! lsirec/lsirec ${LSIREC_ADDR} info | grep -E "IOC is (OPERATIONAL|READY)"
  do
    (( c > 180 )) && echo "timed out" && echo && echo "Operation incomplete, exiting early. Please check the state of the device." && exit 1
    ((c++))
    echo -n "."
    sleep 1
  done
}

function wait_for_mpt {
  local c=0
  echo
  echo -n "Waiting for MPT..."
  while ! lsiutil/lsiutil -e -p1 -a 0 | grep -E "LSI.+SAS2[0-9]{3}"
  do
    (( c > 180 )) && echo "timed out" && echo "Operation incomplete, exiting early. Please check the state of the device." && exit 1
    ((c++))
    echo -n "."
    sleep 1
  done
}

function reset_device {
  wait_for_ioc
  echo "Resetting device..."
  echo
  lsirec/lsirec ${LSIREC_ADDR} reset
  lsirec/lsirec ${LSIREC_ADDR} rescan
  echo
}

# Install necessary packages
apt update
apt install git-core build-essential python3 pciutils p7zip-full sysfsutils unzip -y

# Download and extract firmware/BIOS (maybe)
if [ ! -f "${FIRMWARE_FILE_PATH}" ] || [ ! -f "${BIOS_FILE_PATH}" ]; then
    if [ ! -f "${FIRMWARE_PACKAGE_FILE_NAME}" ]; then
        wget ${FIRMWARE_BIOS_URL} -O "${FIRMWARE_PACKAGE_FILE_NAME}"
    fi
    rm -rf "${FIRMWARE_UNPACK_DIR}"
    unzip "${FIRMWARE_PACKAGE_FILE_NAME}" -d "${FIRMWARE_UNPACK_DIR}"
    FIRMWARE_FILE_PATH="$(find ${FIRMWARE_UNPACK_DIR} -name ${FIRMWARE_FILE_NAME})"
    BIOS_FILE_PATH="$(find ${FIRMWARE_UNPACK_DIR} -name ${BIOS_FILE_NAME})"
fi
[ ! -f "${FIRMWARE_FILE_PATH}" ] && echo "Error: could not find or acquire firmware file at '${FIRMWARE_FILE_PATH}'. No changes have been made." && exit 1
[ ! -f "${BIOS_FILE_PATH}" ] && echo "Error: could not find or acquire BIOS file at '${BIOS_FILE_PATH}'. No changes have been made." && exit 1

# Download and extract UEFI (maybe)
if [ ! -f "${UEFI_FILE_PATH}" ]; then
    if [ ! -f "${UEFI_PACKAGE_FILE_NAME}" ]; then
        wget ${UEFI_URL} -O "${UEFI_PACKAGE_FILE_NAME}"
    fi
    rm -rf "${UEFI_UNPACK_DIR}"
    unzip "${UEFI_PACKAGE_FILE_NAME}" -d "${UEFI_UNPACK_DIR}"
    UEFI_FILE_PATH="$(find ${UEFI_UNPACK_DIR} -name ${UEFI_FILE_NAME} | grep Signed)"
fi
[ ! -f "${UEFI_FILE_PATH}" ] && echo "Error: could not find or acquire UEFI file at '${UEFI_FILE_PATH}'. No changes have been made." && exit 1

# Build megacli
if [ ! -f "${MEGACLI_FILE_NAME}" ]; then
  wget ${MEGACLI_URL} -O "${MEGACLI_FILE_NAME}"
  unzip "${MEGACLI_FILE_NAME}"
  7z x Linux/MegaCli-8.07.14-1.noarch.rpm
  7z x MegaCli-8.07.14-1.noarch.cpio
  chmod 755 opt/MegaRAID/MegaCli/MegaCli64
fi

# Display SAS address and dump to file
opt/MegaRAID/MegaCli/MegaCli64 -AdpAllInfo -a${ADAPTER_INDEX} | grep SAS\ Address
BACKUP_SAS_ADDRESS_FILE="$(find ${BACKUP_ROOT_DIR} -name sas_address.txt)"
SAS_ADDRESS="$(opt/MegaRAID/MegaCli/MegaCli64 -AdpAllInfo -a${ADAPTER_INDEX} | grep -E 'SAS Address[^:]*:\W*(\w+)' | cut -d':' -f2 | cut -d' ' -f2)"
if [ ${#SAS_ADDRESS} -ne 16 ]; then
  echo "Could not retrieve SAS address from MegaCli, attempting to load from existing backup file."
  [ ! -f "${BACKUP_SAS_ADDRESS_FILE}" ] && echo "Error: unable to locate SAS address backup file. No changes have been made." && exit 1
  SAS_ADDRESS=`cat ${BACKUP_SAS_ADDRESS_FILE}`
fi
[ ${#SAS_ADDRESS} -ne 16 ] && echo "Unable to acquire SAS address. No changes have been made." && exit 1
echo "Using SAS address '${SAS_ADDRESS}'"

ADAPTER_BACKUP_DIR="${BACKUP_ROOT_DIR}/${SAS_ADDRESS}"
mkdir -p "${ADAPTER_BACKUP_DIR}"
BACKUP_SAS_ADDRESS_FILE="${ADAPTER_BACKUP_DIR}/sas_address.txt"
BACKUP_PCI_ADDRESS_FILE="${ADAPTER_BACKUP_DIR}/pci_address.txt"

echo "${SAS_ADDRESS}" > ${BACKUP_SAS_ADDRESS_FILE}

# OPTIONAL IF YOU NEED DEB
# apt install alien -y
# alien Linux/MegaCli-8.07.14-1.noarch.rpm --scripts
# dpkg -i megacli_8.07.14-2_all.deb
#

# Build lsiutil
if [ ! -f "${LSIUTIL_FILE_NAME}" ]; then
  wget ${LSIUTIL_URL} -O "${LSIUTIL_FILE_NAME}"
  tar xzf "${LSIUTIL_FILE_NAME}"
  make -C lsiutil -f Makefile_Linux
fi

# Build lsirec
git clone ${LSIREC_REPO_URL}
make -C lsirec

# Unload the HBA kernel module
rmmod megaraid_sas

# Enable huge pages for loading IT firmware from host to card
echo 16 > /proc/sys/vm/nr_hugepages

# Display full PCI information and dump PCI address to file
lspci -mnn | grep -E ${ADAPTER_PATTERN}
PCI_ADDRESS="$(lspci -mnn | grep -E ${ADAPTER_PATTERN} | grep -E '^\w+' | cut -d' ' -f1)"
if [ ${#PCI_ADDRESS} -ne 7 ]; then
  echo "Could not retrieve PCI address from lspci, attempting to load from existing backup file."
  [ ! -f "${BACKUP_PCI_ADDRESS_FILE}" ] && echo "Error: unable to locate PCI address backup file. No changes have been made." && exit 1
  PCI_ADDRESS=`cat ${BACKUP_PCI_ADDRESS_FILE}`
fi
[ ${#PCI_ADDRESS} -ne 7 ] && echo "Error: could not validate PCI address. No changes have been made." && exit 1
echo "${PCI_ADDRESS}" > ${BACKUP_PCI_ADDRESS_FILE}

LSIREC_ADDR="0000:${PCI_ADDRESS}"

# Unbind and halt PCI device
echo "Unbinding and halting device..."
echo
lsirec/lsirec ${LSIREC_ADDR} unbind
lsirec/lsirec ${LSIREC_ADDR} halt
echo

# Read SBR and dump to file
echo "Backing up SBR..."
echo
BACKUP_SBR_FILE="${ADAPTER_BACKUP_DIR}/${SAS_ADDRESS}_backup.sbr"
lsirec/lsirec ${LSIREC_ADDR} readsbr "${BACKUP_SBR_FILE}"
echo

# Extract SBR config
echo "Extracting SBR config..."
echo
BACKUP_SBR_CFG_FILE="${ADAPTER_BACKUP_DIR}/${SAS_ADDRESS}_backup.cfg"
python3 lsirec/sbrtool.py parse "${BACKUP_SBR_FILE}" "${BACKUP_SBR_CFG_FILE}"
echo

# Modify SBR config
echo "Modifying SBR config..."
echo
SBR_CFG_MODIFIED_FILE_PATH="${ADAPTER_BACKUP_DIR}/${SAS_ADDRESS}_modified.cfg"
cp "${BACKUP_SBR_CFG_FILE}" "${SBR_CFG_MODIFIED_FILE_PATH}"
sed -i -r -e "s/^PCIPID = [0-9a-z]+$/PCIPID = 0x0072/I" "${SBR_CFG_MODIFIED_FILE_PATH}"
sed -i -r -e "s/^Interface = [0-9a-z]+$/Interface = 0x00/I" "${SBR_CFG_MODIFIED_FILE_PATH}"
echo

# Create modified SBR
echo "Building new SBR..."
echo
SBR_MODIFIED_FILE="${ADAPTER_BACKUP_DIR}/${SAS_ADDRESS}_modified.sbr"
[ ! -f "${SBR_CFG_MODIFIED_FILE_PATH}" ] && echo "Error: could not find modified SBR cfg file (e.g. H310MM_mod.cfg). No changes have been made." && exit 1
python3 lsirec/sbrtool.py build "${SBR_CFG_MODIFIED_FILE_PATH}" "${SBR_MODIFIED_FILE}"
echo

# Write modified SBR to device
echo "Writing modified SBR to device..."
echo
lsirec/lsirec ${LSIREC_ADDR} writesbr "${SBR_MODIFIED_FILE}"
echo

# Write IT firmware to running image on device and exit reset mode
echo "Writing IT firmware to running image on device..."
echo
lsirec/lsirec ${LSIREC_ADDR} hostboot "${FIRMWARE_FILE_PATH}"
echo

wait_for_ioc

# Rescan device
echo "Starting rescan..."
echo
lsirec/lsirec ${LSIREC_ADDR} rescan
echo

wait_for_mpt

# Use lsiutil to manually do the backup/flashing

# lsiutil/lsiutil -e
  # select the device
    # option 46 (backup)
      # option 5
        # arbitrary file name for backup
    # option 33 (erase)
      # option 3
        # option 8
        # return to main menu
    # option 2 (flash)
      # provide full path to 2118it.bin

# Use lsiutil CLI

# Backup existing flash
echo "Dumping existing flash..."
echo
BACKUP_FIRMWARE_FILE="${ADAPTER_BACKUP_DIR}/${SAS_ADDRESS}_backup.bin"
lsiutil/lsiutil -p1 -a 46,5,0 -f "${BACKUP_FIRMWARE_FILE}"
echo
[ ! -f "${BACKUP_FIRMWARE_FILE}" ] && \
  echo "Error: flash backup not found. Stopping execution." && \
  echo "Please check the state of your device and either:" && \
  echo "  - continue manually" && \
  echo "           or" && \
  echo "  - reflash SBR from ${BACKUP_SBR_FILE} then reboot and (optionally) start over." && \
  echo && \
  exit 1

wait_for_mpt

# Erase flash
echo "Erasing flash..."
echo
lsiutil/lsiutil -p1 -a 33,3,8,,0
echo

wait_for_mpt

# Flash IT firmware
echo "Flashing IT firmware..."
echo
lsiutil/lsiutil -p1 -a 2,yes,0 -f "${FIRMWARE_FILE_PATH}"
echo

reset_device

wait_for_mpt

# Set WWN/SAS Address
echo "Setting WWN/SAS address..."
echo
lsiutil/lsiutil -p1 -a 18,${SAS_ADDRESS},0
echo

reset_device

wait_for_mpt

# Flash BIOS/UEFI
echo "Flashing BIOS/UEFI boot ROMs..."
echo
lsiutil/lsiutil -p1 -a 4,yes,0 -f "${BIOS_FILE_PATH}",,"${UEFI_FILE_PATH}"
echo

echo
echo "All done. Copy /tmp/${SAS_ADDRESS}/ to persistent media and reboot."
echo
