#
# Board configuration for Intel Core-based (Sandy Bridge and later) devices,
# utilizing Mesa for 3D graphics.
#

include device/intel/bigcore/BoardConfig.mk

TARGET_ARCH_VARIANT := sandybridge

# Product specific overlay
PRODUCT_PACKAGE_OVERLAYS += device/intel/core_mesa/overlay

# Using Mesa
BOARD_USE_MESA := true
BOARD_EGL_CFG := device/intel/bigcore/egl_mesa.cfg
BOARD_GPU_DRIVERS := i965
USE_OPENGL_RENDERER := true

# Prevent the ACPI Video module in kernel from
# setting screen brightness, since i915 takes
# care of brightness setting.
BOARD_KERNEL_CMDLINE += acpi_backlight=vendor

ifneq ($(BOARD_USE_DEFAULT_CAMERA_CONFIG),false)
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
                               ro.camera.0.facing=back \
                               ro.camera.0.orientation=0 \

endif # BOARD_USE_DEFAULT_CAMERA_CONFIG != false

# end of file
