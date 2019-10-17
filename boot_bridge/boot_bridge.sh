#!/sbin/sh
#
# Copyright (C) 2016 Adrian DC
#

# Variables
BOOTIMAGE_ORIGINAL=;
BOOTIMAGE_PATH=;
RESULT=${2};

# Bootimage detection based on the find_boot_image logic by Chainfire
for PARTITION in kern-a KERN-A Kernel kernel KERNEL boot BOOT lnx LNX; do
  BOOTIMAGE_PATH=/dev/block/by-name/${PARTITION};
  if [ -L ${BOOTIMAGE_PATH} ] && [ -e ${BOOTIMAGE_PATH} ]; then
    break;
  fi;
  BOOTIMAGE_PATH=/dev/block/platform/*/by-name/${PARTITION};
  if [ -L ${BOOTIMAGE_PATH} ] && [ -e ${BOOTIMAGE_PATH} ]; then
    break;
  fi;
  BOOTIMAGE_PATH=/dev/block/platform/*/*/by-name/${PARTITION};
  if [ -L ${BOOTIMAGE_PATH} ] && [ -e ${BOOTIMAGE_PATH} ]; then
    break;
  fi;
  BOOTIMAGE_PATH=;
done;

# Bootimage recovery detection
if [ -z "${BOOTIMAGE_PATH}" ]; then
  BOOTIMAGE_PATH=$(grep '/boot' /etc/recovery.fstab \
                 | head -n 1 \
                 | xargs -n 1 echo \
                 | grep /dev);
fi;

# Bootimage template linkage
BOOTIMAGE_PATH=$(find ${BOOTIMAGE_PATH} -print -maxdepth 0 | head -n 1);
BOOTIMAGE_ORIGINAL=${BOOTIMAGE_PATH%/*}/boot_original.img;
BOOTIMAGE_BRIDGE=${BOOTIMAGE_PATH%/*}/boot;

# Bootimage not found
if [ -z "${BOOTIMAGE_PATH}" ] || [ -z "${BOOTIMAGE_ORIGINAL}" ]; then
  return 1;
fi;

# Path setup
cd /tmp/;

# Bridge creation
if [ "${1}" = 'init' ]; then

  # ELF bootimage backup
  rm -f "${BOOTIMAGE_ORIGINAL}";
  dd if="${BOOTIMAGE_PATH}" of="${BOOTIMAGE_ORIGINAL}";
  cp "${BOOTIMAGE_PATH}" /tmp/boot_original.img

  # Template bootimage creation
  dd if=/dev/zero of="${BOOTIMAGE_PATH}";
  dd if=/tmp/boot_bridge/boot_template.img of="${BOOTIMAGE_PATH}";

  # Bridge symlink creation
  ln -fs $(readlink -f ${BOOTIMAGE_PATH}) ${BOOTIMAGE_BRIDGE};

  # Transfer ramdisk to template bootimage
  /tmp/boot_bridge/bbootimg -xr "${BOOTIMAGE_ORIGINAL}" ramdisk_original
  /tmp/boot_bridge/bbootimg -u "${BOOTIMAGE_PATH}" -r ramdisk_original
  RESULT=${?};

  # Cleanup failures
  if [ ${RESULT} -ne 0 ]; then
    dd if=/dev/zero of="${BOOTIMAGE_PATH}";
    dd if="${BOOTIMAGE_ORIGINAL}" of="${BOOTIMAGE_PATH}";
    rm -f "${BOOTIMAGE_ORIGINAL}";
    rm -f "${BOOTIMAGE_BRIDGE}";
  fi;

# Bridge restore
else
  # extract ramdisk from boot
  /tmp/boot_bridge/bbootimg -xr "${BOOTIMAGE_PATH}" ramdisk_modified;
  RESULT=${?};

  # ELF bootimage restore
  dd if=/dev/zero of="${BOOTIMAGE_PATH}";
  dd if="${BOOTIMAGE_ORIGINAL}" of="${BOOTIMAGE_PATH}";

  # Transfer ramdisk back to boot image
  if [ ${RESULT} -eq 0 ]; then
    /tmp/boot_bridge/bbootimg -u "${BOOTIMAGE_PATH}" -r ramdisk_modified;
    RESULT=${?};
  fi;

  rm -f "${BOOTIMAGE_ORIGINAL}";
  rm -f "${BOOTIMAGE_BRIDGE}";
fi;

# Result output
return ${RESULT};

