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

# end of file
