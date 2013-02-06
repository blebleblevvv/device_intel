# Board configuration for Lenovo X220t

include device/intel/core_mesa/BoardConfig.mk

# setup additional build prop for product

# Product specific overlay - uncomment this if/when an overlay
# or part of an overlay needs to apply to this target only
PRODUCT_PACKAGE_OVERLAYS += device/intel/lenovox220t/overlay

# Do not use the platform sensor library
BOARD_USE_PLATFORM_SENSOR_LIB := false

# end of file
