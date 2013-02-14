# Superclass
$(call inherit-product, device/intel/common/generic_no_telephony.mk)
$(call inherit-product-if-exists, device/intel/common/multimedia.mk)

# The Superclass may include PRODUCT_COPY_FILES directives that this subclass
# may want to override.  For PRODUCT_COPY_FILES directives the Android Build
# System ignores subsequent copies that lead to the same destination.  So for
# subclass PRODUCT_COPY_FILES to override properly, the right thing to do is to
# prepend them instead of appending them as usual.  This is done using the
# pattern:
#
# OVERRIDE_COPIES := <the list>
# PRODUCT_COPY_FILES := $(OVERRIDE_COPIES) $(PRODUCT_COPY_FILES)

LOCAL_PATH := device/intel/bigcore

PRODUCT_NAME := bigcore
PRODUCT_DEVICE := bigcore

# For device identification to apps
PRODUCT_MANUFACTURER := Generic-IA
PRODUCT_MODEL := Generic-IA

#
# gralloc & mesa lib
#
PRODUCT_PACKAGES += \
    libGLES_mesa    \
    gralloc.$(TARGET_PRODUCT) \
    camera.bigcore \

#
# tinyalsa utils
#
PRODUCT_PACKAGES += \
	tinymix \
	tinyplay \
	tinycap \

# PC std common files
OVERRIDE_COPIES := \
	$(LOCAL_PATH)/android.conf:system/etc/dhcpcd/android.conf \
	$(LOCAL_PATH)/vold.fstab:system/etc/vold.fstab \
	$(LOCAL_PATH)/wpa_supplicant.conf:system/etc/wifi/wpa_supplicant.conf \
	$(LOCAL_PATH)/init.bigcore.rc:root/init.bigcore.rc \
	$(LOCAL_PATH)/init.bigcore.sh:system/etc/init.bigcore.sh \
	$(LOCAL_PATH)/init.bigcore-minimal.rc:root/init.recovery.$(TARGET_PRODUCT).rc \
	device/intel/common/fstab.common:root/fstab.common \
	$(LOCAL_PATH)/modules.blacklist:system/etc/modules.blacklist \
	$(LOCAL_PATH)/ueventd.modules.blacklist:system/etc/ueventd.modules.blacklist \
	$(LOCAL_PATH)/ueventd.bigcore.rc:root/ueventd.$(TARGET_PRODUCT).rc \
	$(LOCAL_PATH)/audio/mixer_paths_Realtek.xml:system/etc/mixer_paths_Realtek.xml \
	$(LOCAL_PATH)/audio/mixer_paths_Analog_Devices.xml:system/etc/mixer_paths_Analog_Devices.xml \
	$(LOCAL_PATH)/audio/mixer_paths_unknown.xml:system/etc/mixer_paths_unknown.xml \

# copy idc files
IDC_FILES := $(wildcard $(LOCAL_PATH)/idc/*.idc)

OVERRIDE_COPIES += \
	$(foreach Item, $(IDC_FILES), $(Item):system/usr/idc/$(notdir $(Item)))

# Likewise add the machine-props files and the dmi-machine.conf
MACH_PROP_FILES = $(wildcard $(LOCAL_PATH)/machine-props/*.prop)
OVERRIDE_COPIES += \
	$(LOCAL_PATH)/dmi-machine.conf:/system/etc/dmi-machine.conf \
	$(foreach F, $(MACH_PROP_FILES), $F:system/etc/machine-props/$(notdir $F))

PRODUCT_COPY_FILES := $(OVERRIDE_COPIES) $(PRODUCT_COPY_FILES)
# for bugmailer
PRODUCT_PACKAGES += send_bug
OVERRIDE_COPIES := \
	system/extras/bugmailer/bugmailer.sh:system/bin/bugmailer.sh \
	system/extras/bugmailer/send_bug:system/bin/send_bug \

PRODUCT_COPY_FILES := $(OVERRIDE_COPIES) $(PRODUCT_COPY_FILES)

# audio support
PRODUCT_PACKAGES += \
	audio.primary.$(TARGET_PRODUCT) \

# a2dp support
PRODUCT_PACKAGES += \
         audio.a2dp.default \

# bluetooth config
PRODUCT_PACKAGES += \
         hciconfig \

# backlight control
PRODUCT_PACKAGES += \
        lights.bigcore \

# hwcomposer
PRODUCT_PACKAGES += \
        hwcomposer.$(TARGET_PRODUCT) \
        hwcomposer.default

PRODUCT_PROPERTY_OVERRIDES += \
        ro.opengles.version = 131072

# Ethernet
PRODUCT_PACKAGES += init.utilitynet.sh

# Uncomment this (or set these properties on a running device) to cause the
# utility network to be statically configured instead of using DHCP:

#PRODUCT_PROPERTY_OVERRIDES += \
#        net.utilitynet.ip=192.168.42.1 \
#        net.utilitynet.netmask=255.255.255.0

# For OTA Update
PRODUCT_PACKAGES += \
	Ota \
	OtaDownloader \

ifneq ($(PANEL_IGNORE_LID),)
	PRODUCT_PROPERTY_OVERRIDES += \
		init.panel_ignore_lid=$(PANEL_IGNORE_LID)
endif

# sensor support
PRODUCT_PACKAGES += \
	sensors.$(TARGET_PRODUCT) \

# systemtap support
PRODUCT_PACKAGES += \
	stap \
	staprun \
	stapio \

PRODUCT_PACKAGES += efibootmgr

# include firmware binaries for Wifi adapters
$(call inherit-product-if-exists, vendor/intel/iwlwifi/iwlwifi.mk)
$(call inherit-product-if-exists, vendor/realtek/realtek.mk)

# tools for Iago installer
$(call inherit-product, bootable/iago/iago.mk)

# include third-party-apps
$(call inherit-product-if-exists, vendor/third-party-apps/third-party-apps.mk)

# for now, sep only compiles on x86 32-bit kernel
ifeq ($(TARGET_ARCH),x86)
$(call inherit-product-if-exists, external/sep/sep.mk)
endif

# end of file
