# Board configuration for Intel PC STD platform

include device/intel/bigcore/BoardConfig.mk

TARGET_ARCH_VARIANT := sandybridge

# Product specific overlay - uncomment this if/when an overlay
# or part of an overlay needs to apply to this target only
# PRODUCT_PACKAGE_OVERLAYS += device/intel/samsungxe700t/overlay

# camera props
# camera.n: n is camera ID to android
# camera.devname: device name of node, e.g. /dev/video0
# number: number of cameras on board. If you claim more than two
#         cameras, Adroid (ICS) will limit it to 2 in run time.
# facing: [front/back]
# orientation: [0/90/180/270]
# If any field is missed or fed with an invalid value, NONE of
# cameras will be reported to Android.

ADDITIONAL_BUILD_PROPERTIES += \
	ro.sf.lcd_density = 160 \
	ro.camera.number=2 \
	ro.camera.0.devname=/dev/video0 \
	ro.camera.0.facing=back \
	ro.camera.0.orientation=0 \
	ro.camera.1.devname=/dev/video1 \
	ro.camera.1.facing=front \
	ro.camera.1.orientation=0 \

TARGET_KERNEL_CONFIG_OVERRIDES += device/intel/samsungxe700t/defconfig_overlay

# Need to load pstore driver (ramoops). Some comments:
#  - memmap was chosen from /proc/iomem by taking the last MB
# from the last "System RAM" entry in the list
#  - the CMDLINE is interpreted by make & bash. Thus the \$$ for representing a $.
BOARD_KERNEL_CMDLINE := $(filter-out androidboot.bcb_device=/dev/block/by-name/misc, $(BOARD_KERNEL_CMDLINE))
BOARD_KERNEL_CMDLINE += \
	memmap=2M\$$0xdaafcfff \
	ramoops.mem_address=0xdaafcfff \
	ramoops.mem_size=0x200000 \
	ramoops.record_size=0x40000 \
	panic=-1 \
	dump_tasks.enabled=1 \
	logger.panic_dump=1 \
	androidboot.bcb_device=/dev/block/sda6 \

ADDITIONAL_BUILD_PROPERTIES += ro.hardKeyboardOverride=true
TARGET_RECOVERY_FSTAB := device/intel/samsungxe700t/recovery.fstab

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

# end of mk file
