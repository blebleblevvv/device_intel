# Board configuration for Intel PC STD platform

include device/intel/bigcore/BoardConfig.mk

TARGET_ARCH_VARIANT := sandybridge

# setup additional build prop for product

# camera props
# camera.n: n is camera ID to android
# camera.devname: device name of node, e.g. /dev/video0
# number: number of cameras on board. If you claim more than two
#         cameras, Adroid (ICS) will limit it to 2 in run time.
# facing: [front/back]
# orientation: [0/90/180/270]
# If any field is missed or fed with an invalid value, NONE of
# cameras will be reported to Android.

BOARD_KERNEL_CMDLINE := $(filter-out androidboot.bcb_device=/dev/block/by-name/misc, $(BOARD_KERNEL_CMDLINE))
BOARD_KERNEL_CMDLINE += androidboot.bcb_device=/dev/block/sda6

ADDITIONAL_BUILD_PROPERTIES += \
	ro.camera.number=1 \
	ro.camera.0.devname=/dev/video0 \
	ro.camera.0.facing=front \
	ro.camera.0.orientation=0 \

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
