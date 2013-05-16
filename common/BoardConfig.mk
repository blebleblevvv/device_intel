
# Used throughout build system to turn on/off custom stuff for x86:
# It is needed, at the very least, to prevent libffi build.
TARGET_ARCH := x86

# Default to SW rendering, override these in product BoardConfig
BOARD_USE_MESA := false
BOARD_GPU_DRIVERS :=
USE_OPENGL_RENDERER := false

# Kernel source and config file that the build system will use for kernel
# build:
ifeq ($(BUILD_EXPERIMENTAL_KERNEL),)
# Use stable kernel
TARGET_KERNEL_SOURCE := kernel/intel
else
# Use experimental kernel, and force building from source
TARGET_KERNEL_SOURCE := kernel/experimental/intel
BUILD_KERNEL := 1
endif

# Gets rid of some annoying compiler warnings during kernel build since
# our GCC is built with nonstandard options
TARGET_KERNEL_EXTRA_CFLAGS += -mfpmath=387

# Kernel prebuilt artifacts. The system *will* check for files existence here,
# so just setting up this variable is safe. However, please note the
# assignment, don't use := because TARGET_PREBUILT_TAG is not available at the
# time this file is parsed, so it might be expanded to a null value.
TARGET_PREBUILT_KERNEL_DIR = $(TARGET_KERNEL_SOURCE)-prebuilt/$(TARGET_PREBUILT_TAG)/kernel/$(TARGET_PRODUCT)-$(TARGET_BUILD_VARIANT)

# Test keys and keygen file to sign kernel modules
TARGET_MODULE_PRIVATE_KEY := device/intel/support/testkeys/bios/DB.key
TARGET_MODULE_CERTIFICATE := device/intel/support/testkeys/bios/DB.DER
TARGET_MODULE_GENKEY := device/intel/support/testkeys/kernel/x509.genkey

# Test key to sign boot image
TARGET_BOOT_IMAGE_KEY := device/intel/support/testkeys/bios/DB.key

# Command run by MKBOOTIMG to sign target's boot image. It is expected to:
# () Take unsigned image from STDIN
# () Output signature's content ONLY to STDOUT
TARGET_BOOT_IMAGE_SIGN_CMD := openssl dgst -sha256 -sign $(TARGET_BOOT_IMAGE_KEY)

BOARD_MKBOOTIMG_ARGS := --signsize 256  --signexec "$(TARGET_BOOT_IMAGE_SIGN_CMD)"

# Enable generation of sparse ext4 images
TARGET_USERIMAGES_SPARSE_EXT_DISABLED := true

# Explicitly required by build/core/config.mk:
TARGET_CPU_ABI := x86

# Since I don't see a build/core/prelink-linux-x86.map file, I guess we
# need to set TARGET_PRELINK_MODULE=false. I don't entirely understand
# this prelink business yet.
TARGET_PRELINK_MODULE := false

# Self-explanatory:
TARGET_USERIMAGES_USE_EXT4 := true

# Used by logic in build/core/kernel.mk; looks for this defconfig inside
# the kernel tree under arch/$(TARGET_ARCH)/configs
# We use '=' since TARGET_KERNEL_ARCH and TARGET_BOARD_PLATFORM aren't set yet
TARGET_KERNEL_CONFIG = $(TARGET_KERNEL_ARCH)_$(TARGET_BOARD_PLATFORM)_android_defconfig

# We turn off some arch-agnostic debug features which have a nontrivial performance
# penalty in user/userdebug builds
ifneq ($(filter user userdebug,$(TARGET_BUILD_VARIANT)),)
TARGET_KERNEL_CONFIG_OVERRIDES := device/intel/common/defconfig_production_overlay
endif

# This eventually gets passed as the length (-l) argument to make_ext4fs
# (system/extras/ext4_utils/make_ext4fs_main.c).  For now it is needed, but
# should consider eliminating the need for it later through the use of a
# sensible default value.
BOARD_BOOTIMAGE_PARTITION_SIZE := 10M

# Attention: Use care when assigning this value; droidboot uses resize2fs which
# is currently afflicted with bug 12919.  The resize will fail with certain
# values, so after making this change, you must test flashing system with droidboot
# to ensure that the size will work.
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 768M
BOARD_USERDATAIMAGE_PARTITION_SIZE := 300M

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

# Flag to tell us when we're on a large-ram device
BOARD_HAS_LARGE_MEMORY := true

# Enable init program to generate bootchart data.
# Variable used by system/core/init/Android.mk
ifeq ($(TARGET_BUILD_VARIANT),eng)
  INIT_BOOTCHART := true
endif

# Choose the version of perf to build based on the relative path
# in the android tree (external/linux-tools-perf or external/perf)
# If it is not set, external/perf will be built.
ifeq ($(BOARD_PERF),)
  BOARD_PERF := external/perf
endif

# Common libraries for the OTA/recovery mechanism
TARGET_RECOVERY_UPDATER_LIBS += libcommon_recovery

# Recovery Console libminui framebuffer pixel format
TARGET_RECOVERY_PIXEL_FORMAT := "BGRA_8888"
RECOVERY_24_BIT := true

# end of file
