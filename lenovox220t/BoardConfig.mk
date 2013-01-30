# Board configuration for Lenovo X220t

include device/intel/core_mesa/BoardConfig.mk

# setup additional build prop for product

BOARD_KERNEL_CMDLINE := $(filter-out androidboot.bcb_device=/dev/block/by-name/misc, $(BOARD_KERNEL_CMDLINE))
BOARD_KERNEL_CMDLINE += androidboot.bcb_device=/dev/block/sda6

# Product specific overlay - uncomment this if/when an overlay
# or part of an overlay needs to apply to this target only
PRODUCT_PACKAGE_OVERLAYS += device/intel/lenovox220t/overlay

# Do not use the platform sensor library
BOARD_USE_PLATFORM_SENSOR_LIB := false

# Causes bootable/diskinstaller/config.mk to be included which enables the
# installer_img build target.  For more information on the installer, see
# http://otc-android.intel.com/wiki/index.php/Installer
TARGET_USE_DISKINSTALLER := true

ifeq ($(TARGET_STAGE_DROIDBOOT),true)
TARGET_DISKINSTALLER_CONFIG := device/intel/samsungxe700t/installer-fastboot.conf
else
TARGET_DISKINSTALLER_CONFIG := device/intel/samsungxe700t/installer.conf
endif

# Defines a partitioning scheme for the installer:
TARGET_DISK_LAYOUT_CONFIG := device/intel/samsungxe700t/disk_layout.conf

# end of file
