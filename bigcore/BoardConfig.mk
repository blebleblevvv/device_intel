# Board configuration for Intel PC STD platform

include device/intel/common/BoardConfig.mk

# 'bigcore' when built directly to use SW rendering, defined in common.mk
ifneq ($(TARGET_PRODUCT),bigcore)
    # Can override in system environment before building
    INTEL_GRAPHICS_DRIVER ?= mesa

    ifeq ($(INTEL_GRAPHICS_DRIVER),mesa)
        BOARD_USE_MESA := true
        BOARD_EGL_CFG := device/intel/bigcore/egl_mesa.cfg
        BOARD_GPU_DRIVERS := i965
        USE_OPENGL_RENDERER := true
    else ifeq ($(INTEL_GRAPHICS_DRIVER),proprietary)
        include vendor/intel/proprietary-graphics/BoardConfigPartial.mk
    endif
endif # !bigcore

# Set default TARGET_ARCH_VARIANT
TARGET_ARCH_VARIANT := x86

# Used for creating/retrieving board-specific prebuilt images
TARGET_BOARD_PLATFORM := bigcore

# Used in ./frameworks/base/services/surfaceflinger/Android.mk
# to set LOCAL_CFLAGS += -DNO_RGBX_8888.
LOCAL_CFLAGS += -DNO_RGBX_8888

TARGET_NO_BOOTLOADER := false

ifeq ($(TARGET_KERNEL_ARCH),)
TARGET_KERNEL_ARCH := i386
endif

# Camera
# Set USE_CAMERA_STUB to 'true' for Fake Camera builds,
# 'false' for libcamera builds to use Camera Imaging(CI) supported by intel.
USE_CAMERA_STUB := true

# Self explanatory. Used by hcidump, glib, bluez, netd, audioflinger,
# etc.
BOARD_HAVE_BLUETOOTH=true

TARGET_USE_SYSLINUX := true
TARGET_SYSLINUX_FILES = device/intel/bigcore/intellogo.png \
		$(SYSLINUX_BASE)/vesamenu.c32 \
		$(SYSLINUX_BASE)/android.c32

ifeq ($(TARGET_STAGE_DROIDBOOT),true)
TARGET_SYSLINUX_CONFIG := device/intel/bigcore/syslinux-fastboot.cfg
TARGET_DISKINSTALLER_CONFIG := device/intel/bigcore/installer-fastboot.conf
INSTALLED_RADIOIMAGE_TARGET += $(PRODUCT_OUT)/droidboot.img
else
TARGET_SYSLINUX_CONFIG := device/intel/bigcore/syslinux.cfg
TARGET_DISKINSTALLER_CONFIG := device/intel/bigcore/installer.conf
endif

DROIDBOOT_HARDWARE_INITRC = device/intel/bigcore/init.droidboot.rc
DROIDBOOT_SCRATCH_SIZE = 1500
TARGET_DROIDBOOT_LIBS := libdbadbd

# Causes bootable/diskinstaller/config.mk to be included which enables the
# installer_img build target.  For more information on the installer, see
# http://otc-android.intel.com/wiki/index.php/Installer
TARGET_USE_DISKINSTALLER := true

# Allow creation of iago live USB/CD images
TARGET_USE_IAGO := true

# Defines a partitioning scheme for the installer:
TARGET_DISK_LAYOUT_CONFIG := device/intel/bigcore/disk_layout.conf

# This defines the overlay that covers all devices inheriting bigcore
DEVICE_PACKAGE_OVERLAYS += device/intel/bigcore/overlay

BOARD_GPS_LIBRARIES := 
BOARD_HAVE_GPS := false

BOARD_USES_LIBPSS := false

BOARD_MODEM_HAVE_DATA_DEVICE := false
BOARD_USES_OPTION_MODEM_AUDIO := false

TARGET_RECOVERY_PIXEL_FORMAT := "BGRA_8888"

BOARD_USE_LIBVA_INTEL_DRIVER := true
BOARD_USE_LIBVA := true
BOARD_USE_LIBMIX := true

TARGET_SYSTEM_PROP := device/intel/bigcore/system.prop

ifeq ($(ANDROID_CONSOLE),usb)
BOARD_CONSOLE_DEVICE := ttyUSB0,115200n8
else ifeq ($(ANDROID_COSNOLE),serial)
BOARD_CONSOLE_DEVICE := ttyS0,115200n8
else
BOARD_CONSOLE_DEVICE := tty0
endif

BOARD_KERNEL_CMDLINE := init=/init pci=noearly \
		console=$(BOARD_CONSOLE_DEVICE) \
		consoleblank=0 vga=current loglevel=5 \
		androidboot.hardware=$(TARGET_PRODUCT) \
		bcb.partno=6 i915.modeset=1 drm.vblankoffdelay=1 \

# --- OTA defines ----

# Python extensions to build/tools/releasetools for constructing
# OTA Update packages
TARGET_RELEASETOOLS_EXTENSIONS := device/intel/bigcore/releasetools.py

# Mapping file so Recovery can format/update filesystems
TARGET_RECOVERY_FSTAB := device/intel/bigcore/recovery.fstab

# Following is used for updating SYSLINUX during OTA.
# Instead of writing the whole bootloader partition,
# we want to update files one by one.
INSTALLED_RADIOIMAGE_TARGET = \
		$(INSTALLED_SYSLINUX_TARGET_EXEC) \
		$(TARGET_SYSLINUX_FILES) \

# end of file
