# Board configuration for Intel PC STD platform

include device/intel/common/BoardConfig.mk

# Set default TARGET_ARCH_VARIANT
TARGET_ARCH_VARIANT := x86

#Not ready to flip this switch yet
#USE_OPENGL_RENDERER := true

# Used in ./frameworks/base/services/surfaceflinger/Android.mk
# to set LOCAL_CFLAGS += -DNO_RGBX_8888.
# TARGET_BOARD_PLATFORM := mrst
LOCAL_CFLAGS += -DNO_RGBX_8888

BOARD_GPU_DRIVERS := i965
BOARD_LIBPCIACCESS_HWDATA := external/hwids

TARGET_NO_BOOTLOADER := false

# The board name as known by Android SDK
TARGET_BOOTLOADER_BOARD_NAME := pc_std

# Kernel source and config file that the build system will use for kernel
# build:
TARGET_KERNEL_SOURCE := kernel/intel
# if TARGET_KERNEL_CONFIG_DIR is empty config is taken from hardware/intel/linux
TARGET_KERNEL_CONFIG_DIR :=
TARGET_KERNEL_CONFIG := $(TARGET_KERNEL_CONFIG_DIR)i386_pc_std_android_defconfig

# Android boot system will look for init.{BOARD,BOOTMEDIA}.rc
# (see below kernel cmdline and system/core/init/init.c)
ifeq ($(BOARD_BOOTMEDIA),)
  BOARD_BOOTMEDIA := harddisk
endif

# Composes a kernel command line which will be used by build/core/Makefile when
# setting up the boot environment.  androidboot.{bootmedia,hardware} are used
# to search for init.*.rc files during init.
# Note that "subarch" numbers are derived from the kernel include file
# arch/x86/include/asm/bootparam.h
BOARD_KERNEL_CMDLINE_FILE := device/intel/pc_std/cmdline
BOARD_KERNEL_CMDLINE := $(shell cat $(BOARD_KERNEL_CMDLINE_FILE))

# Kernel command line for installer. USB is hardcoded. This variable is used as
# part of the arguments for external/genext2fs/mkbootimg_ext2.sh.
TARGET_INSTALLER_BOOTMEDIA = usb

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
BOARD_HAVE_BLUETOOTH=false

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

# Product specific overlay - uncomment this if/when an overlay
# or part of an overlay needs to apply to this target only
PRODUCT_PACKAGE_OVERLAYS := device/intel/pc_std/overlay

# Causes bootable/diskinstaller/config.mk to be included which enables the
# installer_img build target.  For more information on the installer, see
# http://otc-android.intel.com/wiki/index.php/Installer
TARGET_USE_DISKINSTALLER := true

# Defines a partitioning scheme for the installer:
TARGET_DISK_LAYOUT_CONFIG := device/intel/pc_std/disk_layout.conf

BOARD_GPS_LIBRARIES := 
BOARD_HAVE_GPS := false

BOARD_USES_LIBPSS := false

BOARD_MODEM_HAVE_DATA_DEVICE := false
BOARD_USES_OPTION_MODEM_AUDIO := false

TARGET_RELEASETOOLS_EXTENSIONS := device/intel/pc_std/releasetools.py

