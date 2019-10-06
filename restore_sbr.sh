#!/bin/bash

# Must be run as root
[[ $EUID > 0 ]] && echo "Error: must run as root/su" && exit 1

BACKUP_ROOT_DIR="/tmp"

# Get device PCI address
echo "Enter PCI address, or leave blank to discover from expected backup file"
read -p "PCI address: " PCI_ADDRESS

if [ ${#PCI_ADDRESS} -eq 0 ]; then
  echo "Attempting to locate PCI address backup file..."
  BACKUP_PCI_ADDRESS_FILE="$(find ${BACKUP_ROOT_DIR} -name pci_address.txt)"
  [ ! -f "${BACKUP_PCI_ADDRESS_FILE}" ] && echo "Error: unable to locate backup file. No changes have been made." && exit 1
  PCI_ADDRESS=`cat ${BACKUP_PCI_ADDRESS_FILE}`
fi

[ ${#PCI_ADDRESS} -lt 8 ] && PCI_ADDRESS="0000:${PCI_ADDRESS}"
#(echo "${PCI_ADDRESS}" | grep -Eq \d{4}:\d{2}:\w{2}\.\w )
[ ${#PCI_ADDRESS} -ne 12 ] && \
  echo "Error: '${PCI_ADDRESS}' not a valid PCI address. No changes have been made." && \
  exit 1
echo "Using PCI address '${PCI_ADDRESS}'"

# Get backup SBR file
echo "Enter SBR backup file path, original SAS address, or leave blank to discover expected backup files"
read -p "SBR backup file or SAS address: " SAS_ADDRESS

if [ ${#SAS_ADDRESS} -eq 0 ]; then
  echo "Attempting to locate SAS address backup file..."
  BACKUP_SAS_ADDRESS_FILE="$(find ${BACKUP_ROOT_DIR} -name sas_address.txt)"
  [ ! -f "${BACKUP_SAS_ADDRESS_FILE}" ] && echo "Error: unable to locate backup file. No changes have been made." && exit 1
  SAS_ADDRESS=`cat ${BACKUP_SAS_ADDRESS_FILE}`
fi

if (echo ${SAS_ADDRESS} | grep -Eq ^[a-z0-9]{16}$ ); then
  echo "'${SAS_ADDRESS}' is a valid SAS address"
  ADAPTER_BACKUP_DIR="${BACKUP_ROOT_DIR}/${SAS_ADDRESS}"
  BACKUP_SBR_FILE_NAME="${SAS_ADDRESS}_backup.sbr"
  BACKUP_SBR_FILE="$(find ${ADAPTER_BACKUP_DIR} -name ${BACKUP_SBR_FILE_NAME})"
  [ ! -f "${BACKUP_SBR_FILE}" ] && \
    echo "Info: '${BACKUP_SBR_FILE_NAME}' not found in ${ADAPTER_BACKUP_DIR}, going up a level..." && \
    BACKUP_SBR_FILE="$(find ${BACKUP_ROOT_DIR} -name ${BACKUP_SBR_FILE_NAME})"
else
  echo "'${SAS_ADDRESS}' not a valid SAS address."
  BACKUP_SBR_FILE="${SAS_ADDRESS}"
  echo "Attempting to locate SBR backup file at '${BACKUP_SBR_FILE}'..."
fi

[ ! -f "${BACKUP_SBR_FILE}" ] && echo "Error: SBR backup file not found at '${BACKUP_SBR_FILE}'. No changes have been made." && exit 1
echo

# Write modified SBR to device
echo "Writing modified SBR to device..."
echo "Using SBR backup from '${BACKUP_SBR_FILE}'"
lsirec/lsirec ${PCI_ADDRESS} writesbr "${BACKUP_SBR_FILE}"
echo
lsirec/lsirec ${PCI_ADDRESS} info
echo
echo "All done. You should reboot now."
exit 0