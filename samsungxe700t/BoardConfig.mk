# Board configuration for Samsung XE700T

# Camera configuration is done in this file
BOARD_USE_DEFAULT_CAMERA_CONFIG := false

include device/intel/core_mesa/BoardConfig.mk

# Product specific overlay - uncomment this if/when an overlay
# or part of an overlay needs to apply to this target only
# PRODUCT_PACKAGE_OVERLAYS += device/intel/samsungxe700t/overlay

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
	androidboot.bcb_device=/dev/block/sda6 \

ADDITIONAL_BUILD_PROPERTIES += ro.hardKeyboardOverride=true

# end of mk file
