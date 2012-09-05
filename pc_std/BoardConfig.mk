# Board configuration for Intel PC STD platform

include device/intel/common/BoardConfig.mk

# Set default TARGET_ARCH_VARIANT
TARGET_ARCH_VARIANT := x86

USE_OPENGL_RENDERER := true

# Used for creating/retrieving board-specific prebuilt images
TARGET_BOARD_PLATFORM := pc_std

# Used in ./frameworks/base/services/surfaceflinger/Android.mk
# to set LOCAL_CFLAGS += -DNO_RGBX_8888.
LOCAL_CFLAGS += -DNO_RGBX_8888

BOARD_GPU_DRIVERS := i965
BOARD_LIBPCIACCESS_HWDATA := external/hwids

TARGET_NO_BOOTLOADER := false

ifeq ($(TARGET_KERNEL_ARCH),)
TARGET_KERNEL_ARCH := i386
endif

# This variable is used by hardware/alsa_sound/Android.mk.
BOARD_USES_ALSA_AUDIO := true
# Enable alsa utils compilation like aplay for Android
BUILD_WITH_ALSA_UTILS := true
BOARD_USE_VIBRATOR_ALSA := false

# Camera
# Set USE_CAMERA_STUB to 'true' for Fake Camera builds,
# 'false' for libcamera builds to use Camera Imaging(CI) supported by intel.
USE_CAMERA_STUB := true

# Self explanatory. Used by hcidump, glib, bluez, netd, audioflinger, alsa,
# etc.
BOARD_HAVE_BLUETOOTH=true

TARGET_USE_SYSLINUX := true
TARGET_SYSLINUX_FILES = device/intel/pc_std/intellogo.png \
		$(SYSLINUX_BASE)/vesamenu.c32 \
		$(SYSLINUX_BASE)/android.c32
INSTALLED_RADIOIMAGE_TARGET := $(PRODUCT_OUT)/bootloader

ifeq ($(TARGET_STAGE_DROIDBOOT),true)
TARGET_SYSLINUX_CONFIG := device/intel/pc_std/syslinux-fastboot.cfg
TARGET_DISKINSTALLER_CONFIG := device/intel/pc_std/installer-fastboot.conf
INSTALLED_RADIOIMAGE_TARGET += $(PRODUCT_OUT)/droidboot.img
else
TARGET_SYSLINUX_CONFIG := device/intel/pc_std/syslinux.cfg
TARGET_DISKINSTALLER_CONFIG := device/intel/pc_std/installer.conf
endif

DROIDBOOT_HARDWARE_INITRC = device/intel/pc_std/init.droidboot.rc
DROIDBOOT_SCRATCH_SIZE = 1500
TARGET_DROIDBOOT_LIBS := libdbadbd

# Causes bootable/diskinstaller/config.mk to be included which enables the
# installer_img build target.  For more information on the installer, see
# http://otc-android.intel.com/wiki/index.php/Installer
TARGET_USE_DISKINSTALLER := true

# Allow creation of iago live USB/CD images
TARGET_USE_IAGO := true

# Defines a partitioning scheme for the installer:
TARGET_DISK_LAYOUT_CONFIG := device/intel/pc_std/disk_layout.conf

# This defines the overlay that covers all devices inheriting pc_std
DEVICE_PACKAGE_OVERLAYS += device/intel/pc_std/overlay

BOARD_GPS_LIBRARIES := 
BOARD_HAVE_GPS := false

BOARD_USES_LIBPSS := false

BOARD_MODEM_HAVE_DATA_DEVICE := false
BOARD_USES_OPTION_MODEM_AUDIO := false

TARGET_RELEASETOOLS_EXTENSIONS := device/intel/pc_std/releasetools.py

TARGET_RECOVERY_PIXEL_FORMAT := "BGRA_8888"

BOARD_USE_LIBVA_INTEL_DRIVER := true
BOARD_USE_LIBVA := true
BOARD_USE_MESA := true
BOARD_USE_LIBMIX := true

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

# end of file
