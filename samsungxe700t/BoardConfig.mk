# Board configuration for Intel PC STD platform

include device/intel/bigcore/BoardConfig.mk

TARGET_ARCH_VARIANT := sandybridge

# Use Intel wifi
include device/intel/bigcore/BoardConfig-iwlwifi.mk

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
BOARD_KERNEL_CMDLINE += \
	memmap=2M\$$0xdaafcfff \
	ramoops.mem_address=0xdaafcfff \
	ramoops.mem_size=0x200000 \
	ramoops.record_size=0x40000 \
	panic=-1 \
	dump_tasks.enabled=1 \
	logger.panic_dump=1 \

ADDITIONAL_BUILD_PROPERTIES += ro.hardKeyboardOverride=true

# end of mk file
