
# Used throughout build system to turn on/off custom stuff for x86:
# It is needed, at the very least, to prevent libffi build.
TARGET_ARCH := x86

# Kernel source and config file that the build system will use for kernel
# build:
TARGET_KERNEL_SOURCE := kernel/intel
TARGET_KERNEL_CONFIG := $(TARGET_OUT_INTERMEDIATES)/kernel.config

# Kernel prebuilt artifacts. The system *will* check for files existence here,
# so just setting up this variable is safe. However, please note the
# assignment, don't use := because TARGET_PREBUILT_TAG is not available at the
# time this file is parsed, so it might be expanded to a null value.
TARGET_PREBUILT_KERNEL_DIR = $(TARGET_KERNEL_SOURCE)-prebuilt/$(TARGET_PREBUILT_TAG)/kernel/$(TARGET_PRODUCT)-$(TARGET_BUILD_VARIANT)

# Necessary to prevent sparse flag (-s) from being passed to make_ext4fs.
# Droidboot and Diskinstaller do not support writing sparse EXT images yet.
TARGET_USERIMAGES_SPARSE_EXT_DISABLED := true

# Explicitly required by build/core/config.mk:
TARGET_CPU_ABI := x86

# Since I don't see a build/core/prelink-linux-x86.map file, I guess we
# need to set TARGET_PRELINK_MODULE=false. I don't entirely understand
# this prelink business yet.
TARGET_PRELINK_MODULE := false

# Self-explanatory:
TARGET_USERIMAGES_USE_EXT4 := true

# Used by make_kernel_tarball target in
# hardware/intel/linux-2.6/AndroidKernel.mk:
# Notice '=' and not ':='. That is because TARGET_BOARD_PLATFORM has not been defined
# yet by the board-specific makefile.
TARGET_KERNEL_TARBALL = $(TOP)/device/intel/prebuilt/kernel.$(TARGET_BOARD_PLATFORM).tar.gz

# This eventually gets passed as the length (-l) argument to make_ext4fs
# (system/extras/ext4_utils/make_ext4fs_main.c).  For now it is needed, but
# should consider eliminating the need for it later through the use of a
# sensible default value.
BOARD_BOOTIMAGE_PARTITION_SIZE := 10M

# Attention: Use care when assigning this value; droidboot uses resize2fs which
# is currently afflicted with bug 12919.  The resize will fail with certain
# values, so after making this change, you must test flashing system with droidboot
# to ensure that the size will work.
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 512M
BOARD_USERDATAIMAGE_PARTITION_SIZE := 150M

# Copied from generic_x86/BoardConfig.mk. Needed when computing values in
# build/core/definitions.mk.
BOARD_FLASH_BLOCK_SIZE := 512

# Camera texture streaming means that the camera can stream video to an OpenGL
# ES texture.  For more information, see
# http://developer.android.com/reference/android/graphics/SurfaceTexture.html
# This variable is used by the Android CameraService as well as Intel's
# libcamera.
BOARD_USES_CAMERA_TEXTURE_STREAMING := true

# This defines the common overlay that covers all products
# Override on a per product basis by setting PRODUCT_PACKAGE_OVERLAYS
# in a product makefile.
DEVICE_PACKAGE_OVERLAYS := device/intel/common/overlay

# Build Droidboot images for this platform
TARGET_USE_DROIDBOOT := true

# SW Update and provisioning images should put Droidboot on the device
# for users to use via 'adb reboot fastboot'.
# Policy here is to not stage it in production builds
ifneq ($(TARGET_BUILD_VARIANT),user)
TARGET_STAGE_DROIDBOOT := true
else
TARGET_STAGE_DROIDBOOT := false
endif

# Partition configuration file, used by Droidboot
TARGET_DISK_LAYOUT_CONFIG := device/intel/$(TARGET_PRODUCT)/disk_layout.conf

# Used by bootable/recovery/minui
RECOVERY_24_BIT := true

# Flag to tell us when we're on a large-ram device
BOARD_HAS_LARGE_MEMORY := true

# Enable init program to generate bootchart data.
# Variable used by system/core/init/Android.mk
ifeq ($(TARGET_BUILD_VARIANT),eng)
  INIT_BOOTCHART := true
endif
