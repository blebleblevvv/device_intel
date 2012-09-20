# Board configuration for Intel PC STD platform

include device/intel/bigcore/BoardConfig.mk

TARGET_ARCH_VARIANT := sandybridge

# The board name as known by Android SDK
TARGET_BOOTLOADER_BOARD_NAME := samsungxe700t

# Must be set to enable WPA supplicant build. WEXT is the driver for generic
# linux wireless extensions. NL80211 supercedes it.
# This variable is used by external/wpa_supplicant/Android.mk
BOARD_WPA_SUPPLICANT_DRIVER=NL80211
WPA_SUPPLICANT_VERSION:=VER_0_8_X

# set the wifi_driver_basename variable
include device/intel/bigcore/select_wifi_driver.mk

# Tells Android HAL how to load WIFI driver.
# See hardware/libhardware_legacy/wifi/{Android.mk,wifi.c}
WIFI_DRIVER_PROBE_PATH := /system/lib/modules/
WIFI_DRIVER_MODULE_NAME := $(wifi_driver_basename)
# Workarounds for excessive errors that interfere with proper wifi
# operation in the IWLWIFI driver:
#
# plcp_check=N  Works around excessive PLCP health-check failures
#               that cause continuous resetting of RF
# 11n_disable=1 Works around excessive tx retransmits while 11n
#               is enabled, symptom: name-resolve failure
IWLWIFI_PARMLIST := \
	plcp_check=N \
	11n_disable=1 \

WIFI_DRIVER_MODULE_ARG := "$(strip $(IWLWIFI_PARMLIST))"
BOARD_HAVE_WIFI := true
ADDITIONAL_DEFAULT_PROPERTIES += wifi.interface=wlan0

# Product specific overlay - uncomment this if/when an overlay
# or part of an overlay needs to apply to this target only
# PRODUCT_PACKAGE_OVERLAYS := device/intel/samsungxe700t/overlay

TARGET_RECOVERY_UI_LIB := libpcstd_recovery_ui

# setup additional build prop for product

# Enable for boards with sensors
BOARD_USE_PLATFORM_SENSOR_LIB := true

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

# Add power button hack
TARGET_KERNEL_CONFIG_OVERRIDES += device/intel/samsungxe700t/defconfig_overlay

# Need to load pstore driver (ramoops). Some comments:
#  - memmap was chosen from /proc/iomem by taking the last MB
# from the last "System RAM" entry in the list
#  - the CMDLINE is interpreted by make & bash. Thus the \$$ for representing a $.
BOARD_KERNEL_CMDLINE += \
	memmap=1M\$$0xdaafcfff ramoops.mem_address=0xdaafcfff ramoops.mem_size=0x100000 ramoops.record_size=0x32000 \

# end of mk file
