#
# Board configuration for Intel Standard Platform
#

include device/intel/common/BoardConfig.mk


# set console log level
KERNEL_LOGLEVEL ?= 5

ifeq ($(ANDROID_CONSOLE),usb)
BOARD_CONSOLE_DEVICE := ttyUSB0,115200n8
else ifeq ($(ANDROID_CONSOLE),serial)
BOARD_CONSOLE_DEVICE := ttyS0,115200n8
else
BOARD_CONSOLE_DEVICE := tty0
endif

# Board name as known by Android SDK
TARGET_BOOTLOADER_BOARD_NAME := $(TARGET_PRODUCT)

BOARD_KERNEL_CMDLINE := init=/init pci=noearly \
		console=$(BOARD_CONSOLE_DEVICE) \
		consoleblank=0 loglevel=$(KERNEL_LOGLEVEL) \
		androidboot.hardware=$(TARGET_PRODUCT) \
		androidboot.bcb_device=/dev/block/by-name/misc \
		intel_iommu=igfx_off \

# 'bigcore' when built directly to use SW rendering, defined in common.mk
ifneq ($(TARGET_PRODUCT),bigcore)
    BOARD_KERNEL_CMDLINE += vga=current i915.modeset=1 drm.vblankoffdelay=1 \

    ifneq ($(TARGET_BUILD_VARIANT),eng)
        BOARD_KERNEL_CMDLINE += quiet vt.init_hide=1
    endif
else
    BOARD_KERNEL_CMDLINE += vga=ask
endif # !bigcore

# Set default TARGET_ARCH_VARIANT
TARGET_ARCH_VARIANT := x86

# Used for creating/retrieving board-specific prebuilt images
TARGET_BOARD_PLATFORM := bigcore

TARGET_NO_BOOTLOADER := false

ifeq ($(TARGET_KERNEL_ARCH),)
TARGET_KERNEL_ARCH := x86_64
endif

# Camera
# Set USE_CAMERA_STUB to 'true' for Fake Camera builds,
# 'false' for libcamera builds to use Camera Imaging(CI) supported by intel.
USE_CAMERA_STUB := true

# Self explanatory. Used by hcidump, glib, bluez, netd, audioflinger,
# etc.
BOARD_HAVE_BLUETOOTH=true
BOARD_BLUETOOTH_BDROID_BUILDCFG_INCLUDE_DIR := device/intel/bigcore/bluetooth
BOARD_HAVE_BLUETOOTH_BCM := true
BLUETOOTH_HCI_USE_USB := true

# Allow creation of iago live USB/CD images
TARGET_USE_IAGO := true
TARGET_IAGO_PLUGINS := bootable/iago/plugins/gummiboot
TARGET_IAGO_INI := device/intel/bigcore/iago.ini
TARGET_USE_MOKMANAGER := true

TARGET_EFI_APPS := \
	$(PRODUCT_OUT)/efi/gummiboot.efi \
	$(PRODUCT_OUT)/efi/shim.efi \

ifneq ($(TARGET_USE_MOKMANAGER),false)
TARGET_EFI_APPS += $(PRODUCT_OUT)/efi/MokManager.efi
endif

INSTALLED_EFI_BINARY_TARGET += $(TARGET_EFI_APPS)

ifeq ($(TARGET_BUILD_VARIANT),user)
TARGET_IAGO_INI += device/intel/bigcore/iago-production.ini
endif

ifeq ($(TARGET_STAGE_DROIDBOOT),true)
TARGET_IAGO_PLUGINS += bootable/iago/plugins/droidboot
endif

DROIDBOOT_HARDWARE_INITRC = device/intel/bigcore/init.bigcore-minimal.rc
TARGET_RECOVERY_INITRC = device/intel/bigcore/init.bigcore-minimal.rc

DROIDBOOT_SCRATCH_SIZE = 1500
TARGET_DROIDBOOT_LIBS := libdbadbd libdbupdate


# This defines the overlay that covers all devices inheriting bigcore
DEVICE_PACKAGE_OVERLAYS += device/intel/bigcore/overlay

BOARD_GPS_LIBRARIES := 
BOARD_HAVE_GPS := false

BOARD_USES_LIBPSS := false

BOARD_MODEM_HAVE_DATA_DEVICE := false
BOARD_USES_OPTION_MODEM_AUDIO := false

BOARD_USE_LIBVA_INTEL_DRIVER := true
BOARD_USE_LIBVA := true
BOARD_USE_LIBMIX := true

TARGET_SYSTEM_PROP := device/intel/bigcore/system.prop

# Enables bigcore/libsensors/ to be built:
BOARD_USE_PLATFORM_SENSOR_LIB := true

# --- OTA defines ----

# Python extensions to build/tools/releasetools for constructing
# OTA Update packages
TARGET_RELEASETOOLS_EXTENSIONS := device/intel/bigcore/releasetools.py

# Mapping file so Recovery can format/update filesystems
TARGET_RECOVERY_FSTAB := device/intel/bigcore/recovery.fstab

# Addional Edify command implementations
TARGET_RECOVERY_UPDATER_LIBS := libbigcore_updater

# Extra libraries needed to be rolled into recovery updater
TARGET_RECOVERY_UPDATER_EXTRA_LIBS := libgpt_static

# User interface library for Recovery Console.
# Show/hide menu: VOL+ and VOL- chord, or UP and DOWN chord
# Highlight up: UP or Vol+
# Highlight downL DOWN or Vol-
# Select: ENTER or Power
TARGET_RECOVERY_UI_LIB := libbigcore_recovery_ui

# For recovery console minui
TARGET_RECOVERY_PIXEL_FORMAT := "BGRA_8888"

# Use Intel OMX components
BOARD_USES_WRS_OMXIL_CORE := true
USE_INTEL_OMX_COMPONENTS := true

# For wifi
include device/intel/bigcore/wifi/wifi.mk

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
