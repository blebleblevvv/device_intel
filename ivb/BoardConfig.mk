# Board configuration for Ivy Bridge devices

include device/intel/bigcore/BoardConfig.mk

TARGET_ARCH_VARIANT := ivybridge

# Product specific overlay - uncomment this if/when an overlay
# or part of an overlay needs to apply to this target only
PRODUCT_PACKAGE_OVERLAYS += device/intel/ivb/overlay

# end of file
